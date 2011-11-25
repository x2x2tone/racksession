require './sessionapp.rb'
require './sessionproc2'

use Rack::Session::Cookie
use Rack::SessionProc
run TestSession.new
