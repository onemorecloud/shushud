$:.unshift("lib")
$:.unshift("test")

ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.require(:default, :test)

require 'minitest/autorun'
require 'shushu'

class Shushu::Test < MiniTest::Unit::TestCase
  include Rack::Test::Methods
  include Shushu

  def clean_tables
    DB.run("DELETE FROM rate_codes CASCADE")
    DB.run("DELETE FROM billable_events CASCADE")
    DB.run("DELETE FROM providers CASCADE")
  end

  def setup
    clean_tables
  end

  def teardown
    clean_tables
  end

  def build_provider(opts={})
    Provider.create({
      :name  => "sendgrid",
      :token => "password"
    }.merge(opts))
  end

  def build_rate_code(opts={})
    RateCode.create({
      :slug => "RT01",
      :rate => 5,
      :description => "dyno hour"
    }.merge(opts))
  end

  def app
    Rack::Builder.new do
      map("/resources")  { run Shushu::Web::Api }
      map("/rate_codes") { run Shushu::Web::RateCodeApi }
      map("/providers")  { run Shushu::Web::ProviderApi }
    end
  end
  
end
