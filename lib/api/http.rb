require './lib/billable_event'
require './lib/rate_code'
require './lib/resource_ownership'

module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    register Sinatra::Instrumentation
    instrument_routes

    before do
      authenticate_provider
      content_type(:json)
    end

    error do
      e = env['sinatra.error']
      log({level: "error", exception: e.message}.merge(params))
      [500, j(msg: "un-handled error")]
    end

    not_found do
      [404, j(msg: "endpoint not found")]
    end

    head "/" do
      200
    end

    get "/heartbeat" do
      [200, j(alive: Time.now)]
    end

    put "/resources/:hid/billable_events/:entity_id" do
      Shushu::BillableEvent.
        handle_in(provider_id: session[:provider_id],
                   rate_code: params[:rate_code],
                   product_name: params[:product_name],
                   description: params[:description],
                   hid: params[:hid],
                   entity_id_uuid:  params[:entity_id_uuid],
                   entity_id: params[:entity_id],
                   qty: params[:qty],
                   time: dec_time(params[:time]),
                   state: params[:state])
    end

    put "/accounts/:account_id/resource_ownerships/:entity_id" do
      Shushu::ResourceOwnership.
        handle_in(params[:state], session[:provider_id], params[:account_id],
                   params[:resource_id], dec_time(params[:time]),
                   params[:entity_id])
    end

    post "/rate_codes" do
      Shushu::RateCode.
        handle_in(provider_id: session[:provider_id],
                   rate: params[:rate],
                   period: params[:period],
                   product_group: params[:group],
                   product_name: params[:name])
    end

    put "/rate_codes/:slug" do
      Shushu::RateCode.
        handle_in(provider_id: session[:provider_id],
                   slug: params[:slug],
                   rate: params[:rate],
                   period: params[:period],
                   product_group: params[:group],
                   product_name: params[:name])
    end

  end
end
