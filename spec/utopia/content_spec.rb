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

require_relative 'spec_helper'

require 'utopia/content'

module Utopia::ContentSpec
	class TestDelegate
		def initialize
			@events = []
		end
		
		attr :events
		
		def method_missing(*args)
			@events << args
		end
	end
	
	describe Utopia::Content::Processor do
		it "should format open tags correctly" do
			foo_tag = Utopia::Content::Tag.new("foo", bar: nil, baz: 'bob')
			
			expect(foo_tag[:bar]).to be nil
			expect(foo_tag[:baz]).to be == 'bob'
			
			expect(foo_tag.to_s('content')).to be == '<foo bar baz="bob">content</foo>'
		end
		
		it "should parse single tag" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			processor.parse %Q{<foo></foo>}
			
			foo_tag = Utopia::Content::Tag.new("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
			
			expect(foo_tag.to_s)
		end
		
		it "should parse and escape text" do
			delegate = TestDelegate.new
			processor = Utopia::Content::Processor.new(delegate)
			
			processor.parse %Q{<foo>Bob &amp; Barley<!-- Comment --><![CDATA[Hello & World]]></foo>}
			
			foo_tag = Utopia::Content::Tag.new("foo")
			expected_events = [
				[:tag_begin, foo_tag],
				[:cdata, "Bob &amp; Barley"],
				[:cdata, "<!-- Comment -->"],
				[:cdata, "Hello &amp; World"],
				[:tag_end, foo_tag],
			]
			
			expect(delegate.events).to be == expected_events
		end
	end
	
	describe Utopia::Content do
		include Rack::Test::Methods
		
		let(:app) {Rack::Builder.parse_file(File.expand_path('../content_spec.ru', __FILE__)).first}
		
		it "should successfully redirect to the index page" do
			get '/'
			
			expect(last_response.status).to be == 307
			expect(last_response.headers['Location']).to be == '/index'
			
			get '/content'
			
			expect(last_response.status).to be == 307
			expect(last_response.headers['Location']).to be == '/content/index'
		end
		
		it "should successfully render the index page" do
			get "/index"
			
			expect(last_response.body).to be == '<h1>Hello World</h1>'
		end
		
		it "should render partials correctly" do
			get "/content/test-partial"
			
			expect(last_response.body).to be == '10'
		end
	end
	
	describe Utopia::Content do
		it "Should parse file and expand variables" do
			root = File.expand_path("../pages", __FILE__)
			content = Utopia::Content.new(lambda{}, :root => root)
		
			path = Utopia::Path.create('/index')
			node = content.lookup_node(path)
			expect(node).to be_kind_of Utopia::Content::Node
		
			output = StringIO.new
			node.process!({}, output, {})
			expect(output.string).to be == '<h1>Hello World</h1>'
		end
	end
end