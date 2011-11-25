require 'rack'

class TestCaller
	def call(env)
		req = Rack::Request.new(env)
		session_data = env['rack.session']
		session_data["counter"] ||= 0
		session_data["counter"] += 1
		Rack::Response.new.finish do |res|
			res.write "<li>counter : #{session_data.class}</li>"
		end
	end
end
