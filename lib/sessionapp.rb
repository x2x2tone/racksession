require 'rack'
require './sessionproc'

class TestSession
	def call(env)
		session_data = env['rack.session']
		session_data.create_new_id

		#ここでは@@sessiondataを直接編集しないほうがいいかも
		session_data["counter"] ||= 0
		session_data["counter"] += 1
		Rack::Response.new.finish do |res|
			res.write "<li>counter : #{session_data['counter']}</li>"
		end
	end
end
