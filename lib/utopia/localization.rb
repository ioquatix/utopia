# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'middleware'
require_relative 'localization/name'

module Rack
	class Request
		def current_locale
			env[Utopia::Localization::CURRENT_LOCALE_KEY]
		end
		
		def all_locales
			localization.all_locales
		end
		
		def localization
			env[Utopia::Localization::LOCALIZATION_KEY]
		end
	end
end

module Utopia
	class Localization
		LOCALIZATION_KEY = 'utopia.localization'.freeze
		CURRENT_LOCALE_KEY = 'utopia.current_locale'.freeze
		
		def initialize(app, options = {})
			@app = app

			@default_locale = options[:default] || "en"
			@all_locales = options[:locales] || ["en"]
			
			@nonlocalized = options[:nonlocalized] || []
		end

		def named_locale(resource_name)
			if resource_name
				Name.extract_locale(resource_name, @all_locales)
			else
				nil
			end
		end

		attr :all_locales
		attr :default_locale
		
		def check_resource(resource_name, resource_locale, env)
			localized_name = Name.localized(resource_name, resource_locale, @all_locales).join(".")
			localized_path = Path.create(env["PATH_INFO"]).dirname + localized_name

			localization_probe = env.dup
			localization_probe["REQUEST_METHOD"] = "HEAD"
			localization_probe["PATH_INFO"] = localized_path.to_s

			# Find out if a resource exists for the requested localization
			return [localized_path, @app.call(localization_probe)]
		end

		def nonlocalized?(env)
			@nonlocalized.each do |pattern|
				case pattern
				when String
					return true if env["PATH_INFO"].start_with?(pattern)
				when Regexp
					return true if pattern.match(env["PATH_INFO"])
				when pattern.respond_to?(:call)
					return true if pattern.call(env)
				end
			end
			
			return false
		end

		def call(env)
			# Check for a non-localized resource.
			if nonlocalized?(env)
				return @app.call(env)
			end
			
			# Otherwise, we need to check if the resource has been localized based on the request and referer parameters.
			path = Path.create(env["PATH_INFO"])
			env[LOCALIZATION_KEY] = self

			referer_locale = named_locale(env['HTTP_REFERER'])
			request_locale = named_locale(path.basename)
			resource_name = Name.nonlocalized(path.basename, @all_locales).join(".")

			response = nil
			if request_locale
				env[CURRENT_LOCALE_KEY] = request_locale
				resource_path, response = check_resource(resource_name, request_locale, env)
			elsif referer_locale
				env[CURRENT_LOCALE_KEY] = referer_locale
				resource_path, response = check_resource(resource_name, referer_locale, env)
			end
			
			# If the previous checks failed, i.e. there was no request/referer locale 
			# or the response was 404 (i.e. no localised resource), we check for the
			# @default_locale
			if response == nil || response[0] >= 400
				env[CURRENT_LOCALE_KEY] = @default_locale
				resource_path, response = check_resource(resource_name, @default_locale, env)
			end

			# If the response is 2xx, we have a localised resource
			if response[0] < 300
				# If the original request was the same as the localized request,
				if path.basename == resource_path.basename
					# The resource URI is correct.
					return @app.call(env)
				else
					# Redirect to the correct resource URI.
					return [307, {"Location" => resource_path.to_s}, []]
				end
			elsif response[0] < 400
				# We have encountered a redirect while accessing the localized resource
				return response
			else
				# A localized resource was not found, return the unlocalised resource path,
				if path.basename == resource_name
					return @app.call(env)
				else
					return [307, {"Location" => (path.dirname + resource_name).to_s}, []]
				end
			end
		end
	end
end