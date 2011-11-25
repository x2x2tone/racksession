require 'rack'

module Rack
	class SessionProc
		
		def initialize(app,opt={})
			@app = app
			@session = nil
		end

		def call(env)
			load_session(env)
			status, headers, body = @app.call(env)
			commit_session(env, status, headers, body)
		end

		private

		def load_session(env)
			@session = SessionData.new(env)
			env['rack.session'] = @session
		end

		def commit_session(env, status, headers, body)
			@session = env['rack.session']
			if @session.new_session_id
				@session.set_session
				options = env['rack.session.options']
				cookie = {:value => @session.session_key}
				cookie[:expires] = Time.now + options[:expire_after] unless options[:expire_after].nil?
				response = Rack::Response.new(body, status, headers)
				response.set_cookie(@session.key, cookie.merge(options))
				return response.to_a
#			elsif @session.change?
#				@session.change
			end
			[status, headers, body]
		end

	end

	class SessionData  < Hash
		@@sessiondata = {}
		attr_reader :session_data, :session_key, :key

		def initialize(env,opt={})
			@key = opt[:key] || "rack.session.id"
			@default_options = {:domain => nil,
													:path => "/",
													:expire_after => nil}.merge(opt)

			req = Rack::Request.new(env)
			session_key = req.cookies[@key]
			env["rack.session.options"] = @default_options.dup
			
			#直接触るので不要？？ でもIFがわかりにくい。
			#@session_data = (@@sessiondata[session_key] || {}).dup
			@new_session_id = nil
			@old_session_id = @session_key = session_key
			puts "@old_session_id: #{@old_session_id}"
		end
	
		def create_new_id(renew = false)
				return @old_session_id if !renew && @old_session_id
				require 'digest/md5'
				md5 = Digest::MD5.new
				now = Time.now
				md5.update(now.to_s)
				md5.update(String(now.usec))
				md5.update('foobar')
				md5.update($$.to_s)
				md5.update(String(rand(0)))
				@new_session_id = md5.hexdigest
		end

		def new_session_id
			@new_session_id
		end
		
		def set_session
			@@sessiondata.delete(@old_session_id) if @old_session_id
			@session_key = @new_session_id
			puts "session_key :#{@session_key}"

			#APP側でenv['rack.session']につめているので
			#ここで再設定する必要ないかも、
			#@@sessiondata[@session_key] = @session_data
		end

=begin
		def change?
			@session_key && @@sessiondata[@session_key] != @session_data
		end

		def change
			#@@sessiondata[@session_key] = @session_data
		end
=end

		def []=(k, val)
			h = @@sessiondata[@session_key] || {}
			h[k] = val
			@@sessiondata[@session_key] = h
		end

		def [](k)
			h = @@sessiondata[@session_key]
			unless h.nil?
				puts "h #{h}"
				puts "h[k] #{h[k]}"
				return h[k]
			end
		end
	end

end

