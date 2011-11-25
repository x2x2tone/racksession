require 'rack'

module Rack
	class SessionProc
		@@sessiondata = {}
		
		def initialize(app,opt={})
			@app = app
			@key = opt[:key] || "rack.session.id"
			@default_options = {:domain => nil,
													:path => "/",
													:expire_after => nil}.merge(opt)
		end

		def call(env)
			load_session(env)
			# Aで設定した環境変数を引数にしてrackアプリへ
			status, headers, body = @app.call(env)
			commit_session(env, status, headers, body)
		end

		private

		def load_session(env)
			#リクエストからsessionkeyを取得
			#Cookieのrack.sessionまたはsessionクラス変数からsessionを取得
			#
			req = Rack::Request.new(env)
			session_key = req.cookies[@key]
			env["rack.session.options"] = @default_options.dup

			#環境変数rack.sessionをI/Fにしてセッション情報を格納・・A
			session_data = env['rack.session'] = (@@sessiondata[session_key] || {}).dup
			def session_data.create_new_id(renew = false)
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

			def session_data.new_session_id
				@new_session_id
			end

			def session_data._init(id)
				@new_session_id = nil
				@old_session_id = id
				puts "@old_session_id: #{@old_session_id}"
				self
			end

			session_data._init(session_key)
		end

		def commit_session(env, status, headers, body)
			# load_sessionと内容が重複していて冗長 <--誤り
			# appで設定したセッション情報を環境変数で受け取る
			session_data = env['rack.session']
			req = Rack::Request.new(env)
			session_key = req.cookies[@key]

			if session_data.new_session_id
				@@sessiondata.delete(session_key) if session_key
				session_key = session_data.new_session_id
				puts "session_key :#{session_key}"
				@@sessiondata[session_key] = session_data

				options = env['rack.session.options']
				cookie = {:value => session_key}
				cookie[:expires] = Time.now + options[:expire_after] unless options[:expire_after].nil?
				response = Rack::Response.new(body, status, headers)
				response.set_cookie(@key, cookie.merge(options))
				return response.to_a
			elsif session_key && @@sessiondata[session_key] != session_data
				@@sessiondata[session_key] = session_data
			end
			[status,headers, body]
		end

	end
end

=begin
# session_dataの特異メソッドにする必要があるか？
	class << Rack::Session::Abstract::SessionHash
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

		def _init(id)
			@new_session_id = nil
			@old_session_id = id
			puts "@old_session_id: #{@old_session_id}"
			self
		end
	end
=end
