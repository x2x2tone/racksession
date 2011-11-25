require './testapp.rb'

use Rack::Session::Cookie
run TestCaller.new
