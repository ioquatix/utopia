# Controller

A simple recursive controller layer which works in isolation from the view rendering middleware.

```ruby
use Utopia::Controller,
	# The root directory where `controller.rb` files can be found.
	root: 'path/to/root',
	# The base class to use for all controllers:
	base: Utopia::Controller::Base,
	# Whether or not to cache controller classes:
	cache_controllers: (RACK_ENV == :production)
```

A controller is a file within the root directory (or subdirectory) with the name `controller.rb`. This code is dynamically loaded into an anonymous class and executed. The default controller has only a single function:

```ruby
def passthrough(request, path)
	# Call one of:
	
	# This will cause the middleware to generate a response.
	# def respond!(response)

	# This will cause the controller to skip the request.
	# def ignore!

	# Request relative redirect. Respond with a redirect to the given target.
	# def redirect! (target, status = 302)
	
	# Controller relative redirect.
	# def goto!(target, status = 302)
	
	# Respond with an error which indiciates some kind of failure.
	# def fail!(error = 400, message = nil)
	
	# Succeed the request and immediately respond.
	# def succeed!(status: 200, headers: {}, **options)
	# options may include content: string or body: Enumerable (as per Rack specifications
end
```

The controller layer can do more complex operations by prepending modules into it.

```ruby
prepend Rewrite, Actions

# Extracts an Integer
rewrite.extract_prefix id: Integer do
	@user = User.find_by_id(@id)
end

on 'edit' do |request, path|
	if request.post?
		@user.update_attributes(request[:user])
	end
end

otherwise do |request, path|
	# Executed if no specific named actions were executed.
	succeed!
end
```
