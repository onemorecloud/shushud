module Api
  class Http < Sinatra::Base
    include Authentication
    include Helpers

    before {authenticate_provider; content_type(:json)}
    #
    # Errors
    #
    not_found do
      status(404)
      body(enc_json("Not Found"))
    end

    delete "/sessions" do
      session.clear
    end

    #
    # Heartbeat
    #
    get "/heartbeat" do
      if r = params[:redirect_to]
        redirect(r)
      else
        status(200)
        body({:alive => Time.now})
      end
    end

    #
    # Accounts
    #
    post "/accounts" do
      perform do
        [201, Account.create.to_h]
      end
    end

    #
    # Receivables
    #
    post "/receivables" do
      perform do
        ReceivablesService.create(
          enc_int(params[:init_payment_method_id]),
          enc_int(params[:amount]),
          enc_time(params[:from]),
          enc_time(params[:to])
        )
      end
    end

    #
    # PaymentAttempts
    #
    post "/receivables/:receivable_id/payment_attempts" do
      perform do
        PaymentService.attempt(
          enc_int(params[:receivable_id]),
          enc_int(params[:payment_method_id]),
          enc_time(params[:wait_until])
        )
      end
    end

    #
    # Reports
    #
    get "/accounts/:account_id/usage_reports" do
      perform do
        ReportService.usage_report(params[:account_id], dec_time(params[:from]), dec_time(params[:to]))
      end
    end

    #
    # BillableEvents
    #
    get "/billable_events" do
      perform do
        BillableEventService.find(enc_int(session[:provider_id]))
      end
    end

    put "/resources/:hid/billable_events/:entity_id" do
      perform do
        BillableEventService.handle_new_event(
          :provider_id    => session[:provider_id],
          :rate_code_slug => params[:rate_code],
          :product_name   => params[:product_name],
          :hid            => params[:hid],
          :entity_id      => params[:entity_id],
          :qty            => params[:qty],
          :time           => dec_time(params[:time]),
          :state          => params[:state]
        )
      end
    end

    #
    # AccountOwnership
    #
    post "/payment_methods/:payment_method_id/account_ownerships/:entity_id" do
      perform do
        AccountOwnershipService.activate(
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:entity_id]
        )
      end
    end

    put "/payment_methods/:prev_payment_method_id/account_ownerships/:prev_entity_id" do
      perform do
        AccountOwnershipService.transfer(
          dec_int(params[:prev_payment_method_id]),
          dec_int(params[:payment_method_id]),
          dec_int(params[:account_id]),
          dec_time(params[:time]),
          params[:prev_entity_id],
          params[:entity_id]
        )
      end
    end

    #
    # ResourceOwnership
    #
    get "/accounts/:account_id/resource_ownerships" do
      perform do
        ResourceOwnershipService.query(params[:account_id])
      end
    end

    post "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.activate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:entity_id])
      end
    end

    put "/accounts/:prev_account_id/resource_ownerships/:prev_entity_id" do
      perform do
        ResourceOwnershipService.transfer(
          dec_int(params[:prev_account_id]),
          dec_int(params[:account_id]),
          params[:hid],
          dec_time(params[:time]),
          params[:prev_entity_id],
          params[:entity_id]
        )
      end
    end

    delete "/accounts/:account_id/resource_ownerships/:entity_id" do
      perform do
        ResourceOwnershipService.deactivate(dec_int(params[:account_id]), params[:hid], dec_time(params[:time]), params[:entity_id])
      end
    end

    #
    # RateCode
    #
    post "/providers/:target_provider_id/rate_codes" do
      perform do
        RateCodeService.create(
          :provider_id        => session[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    post "/rate_codes" do
      perform do
        RateCodeService.create(
          :provider_id        => session[:provider_id],
          :slug               => params[:slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    put "/rate_codes/:rate_code_slug" do
      perform do
        RateCodeService.update(
          :provider_id        => session[:provider_id],
          :target_provider_id => params[:target_provider_id],
          :slug               => params[:rate_code_slug],
          :rate               => params[:rate],
          :product_group      => params[:group],
          :product_name       => params[:name]
        )
      end
    end

    get "/rate_codes/:rate_code_slug" do
      perform do
        RateCodeService.find(params[:rate_code_slug])
      end
    end

    def perform
      begin
        s, b = yield
        status(s)
        body(enc_json(b))
      rescue RuntimeError, ArgumentError => e
        log("#http_api_runtime_error e=#{e.message} s=#{e.backtrace}")
        status(400)
        body(enc_json(e.message))
      rescue Shushu::AuthorizationError => e
        log("#http_api_authorization_error e=#{e.message} s=#{e.backtrace}")
        status(403)
        body(enc_json(e.message))
      rescue Shushu::NotFound => e
        log("#http_api_find_error e=#{e.message} s=#{e.backtrace}")
        status(404)
        body(enc_json(e.message))
      rescue Shushu::DataConflict => e
        log("#http_api_data_error e=#{e.message} s=#{e.backtrace}")
        status(409)
        body(enc_json(e.message))
      rescue Exception => e
        log("#http_api_error e=#{e.message} s=#{e.backtrace}")
        status(500)
        body(enc_json(e.message))
        raise if Shushu.test?
      end
    end

    def log(msg)
      Log.info("account=#{params[:account_id]} provider=#{session[:provider_id]} hid=#{params[:hid]} #{msg}")
    end

  end
end
