class HttpApi < Sinatra::Base

  NotFound            = Class.new(Exception)
  DataConflict        = Class.new(Exception)
  AuthorizationError  = Class.new(Exception)

  helpers {include Authentication}
  before  {content_type(:json)}

  #
  # Heartbeat
  #
  get "/heartbeat" do
    authenticate_provider
    status(200)
    body({:alive => Time.now})
  end

  #
  # BillableEvents
  #
  get "/resources/:hid/billable_events" do
    authenticate_provider #sets params[:provider_id]
    perform do
      BillableEventService.find({:hid => params[:hid], :provider_id => params[:provider_id]})
    end
  end

  put "/resources/:hid/billable_events/:event_id" do
    authenticate_provider #sets params[:provider_id]
    perform do
      BillableEventService.handle_new_event(
        :provider_id    => params[:provider_id],
        :rate_code_slug => params[:rate_code],
        :hid            => params[:hid],
        :event_id       => params[:event_id],
        :qty            => params[:qty],
        :time           => params[:time],
        :state          => params[:state]
      )
    end
  end

  #
  # ResourceOwnership
  #
  get "/resource_ownerships" do
    authenticate_trusted_consumer
    perform do
      ResourceOwnershipService.query(params[:account_id], params[:hid])
    end
  end

  post "/resource_ownerships" do
    authenticate_trusted_consumer
    perform do
      ResourceOwnershipService.activate(params[:account_id], params[:hid])
    end
  end

  put "/resource_ownerships" do
    authenticate_trusted_consumer
    perform do
      ResourceOwnershipService.transfer(params[:prev_account_id], params[:account_id], params[:hid])
    end
  end

  #
  # RateCode
  #
  post "/providers/:target_provider_id/rate_codes" do
    authenticate_provider
    perform do
      RateCodeService.create(
        :provider_id        => params[:provider_id],
        :target_provider_id => params[:target_provider_id],
        :slug               => params[:slug],
        :rate               => params[:rate],
        :product_group      => params[:group],
        :product_name       => params[:name]
      )
    end
  end

  post "/rate_codes" do
    authenticate_provider
    perform do
      RateCodeService.create(
        :provider_id        => params[:provider_id],
        :slug               => params[:slug],
        :rate               => params[:rate],
        :product_group      => params[:group],
        :product_name       => params[:name]
      )
    end
  end

  put "/rate_codes/:rate_code_slug" do
    authenticate_provider
    perform do
      RateCodeService.update(
        :provider_id        => params[:provider_id],
        :target_provider_id => params[:target_provider_id],
        :slug               => params[:rate_code_slug],
        :rate               => params[:rate],
        :product_group      => params[:group],
        :product_name       => params[:name]
      )
    end
  end

  get "/rate_codes/:rate_code_slug" do
    authenticate_provider
    perform do
      RateCodeService.find(params[:rate_code_slug])
    end
  end

  def perform
    begin
      exception_message = nil
      res = yield
      json_res = if res.respond_to?(:to_h)
        JSON.dump(res.to_h)
      else
        JSON.dump(res)
      end
      status(status_based_on_verb(request.request_method))
      body(json_res)
    rescue RuntimeError => e
      log("#http_api_runtime_error e=#{e.message} s=#{e.backtrace}")
      status(400)
      body(e.message)
    rescue AuthorizationError => e
      log("#http_api_authorization_error e=#{e.message} s=#{e.backtrace}")
      status(403)
      body(e.message)
    rescue NotFound => e
      log("#http_api_find_error e=#{e.message} s=#{e.backtrace}")
      status(404)
      body(e.message)
    rescue DataConflict => e
      log("#http_api_data_error e=#{e.message} s=#{e.backtrace}")
      status(409)
      body(e.message)
    rescue Exception => e
      log("#http_api_error e=#{e.message} s=#{e.backtrace}")
      status(500)
      body(e.message)
      raise if Shushu.test?
    end
  end

  def status_based_on_verb(verb)
    case verb
    when "POST" then 201
    when "PUT"  then 200
    end
  end

  def log(msg)
    shulog("account=#{params[:account_id]} provider=#{params[:provider_id]} hid=#{params[:hid]} #{msg}")
  end

end
