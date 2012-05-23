module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    register Sinatra::Instrumentation
    instrument_routes

    before {authenticate_provider; content_type(:json)}

    #
    # Errors
    #
    not_found do
      perform do
        [404, "Not Found"]
      end
    end

    #
    # Heartbeat
    #
    get "/heartbeat" do
      perform do
        [200, {:alive => Time.now}]
      end
    end

    #
    # Accounts
    #
    post "/accounts" do
      perform do
        [201, Account.create(:provider_id => session[:provider_id]).to_h]
      end
    end

    #
    # BillableEvents
    #
    put "/resources/:hid/billable_events/:entity_id" do
      perform do
        BillableEventService.handle_in(
          :provider_id    => session[:provider_id],
          :rate_code      => params[:rate_code],
          :product_name   => params[:product_name],
          :description    => params[:description],
          :hid            => params[:hid],
          :entity_id_uuid => params[:entity_id_uuid],
          :entity_id      => params[:entity_id],
          :qty            => params[:qty],
          :time           => dec_time(params[:time]),
          :state          => params[:state]
        )
      end
    end

    #
    # ResourceOwnership
    #
    put "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.handle_in(
          params[:state],
          session[:provider_id],
          params[:account_id],
          params[:resource_id],
          dec_time(params[:time]),
          params[:entity_id]
        )
      end
    end

    #
    # RateCode
    #
    post "/rate_codes" do
      perform do
        RateCodeService.handle_in(
          :provider_id   => session[:provider_id],
          :rate          => params[:rate],
          :period        => params[:period],
          :product_group => params[:group],
          :product_name  => params[:name]
        )
      end
    end

    put "/rate_codes/:slug" do
      perform do
        RateCodeService.handle_in(
          :provider_id   => session[:provider_id],
          :slug          => params[:slug],
          :rate          => params[:rate],
          :period        => params[:period],
          :product_group => params[:group],
          :product_name  => params[:name]
        )
      end
    end

    def perform
      begin
        s, b = yield
        status(s)
        body(enc_json(b))
      rescue RuntimeError, ArgumentError => e
        log({:level => :error, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        log({:level => :error, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        log({:level => :error, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        log({:level => :error, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        log({:level => :error, :exception => e.message, :backtrace => e.backtrace}.merge(params))
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end
  end
end
