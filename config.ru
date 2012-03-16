require './lib/shushu'
require "sinatra"

use Rack::CommonLogger
use Rack::Session::Cookie,
  :path            => "/",
  :key             => "shushu.session",
  :secret          => ENV["SESSION_SECRET"],
  :expire_after    => 120

run Api::HeartBeat
run Api::Http
