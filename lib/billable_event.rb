require './lib/shushu'
require './lib/utils'

module Shushu
  module BillableEvent
    extend self

    OPEN = 1
    CLOSED = 0

    def handle_in(args)
      return [400, j(msg: "invalid args")] unless valid_args?(args)
      if args[:state] == "open"
        if prev_opened?(args[:entity_id_uuid])
          [200, j(msg: "OK")]
        elsif open_event(args)
          [201, j(msg: "OK")]
        else
          [400, j(error: "unable to open event")]
        end
      elsif args[:state] == "close"
        Utils.txn do
          if prev_closed?(args[:entity_id_uuid])
            [200, j(msg: "OK")]
          elsif open = delete_event(args[:entity_id_uuid])
            if close_event(open, args)
              [201, j(msg: "OK")]
            else
              [400, j(error: "unable to open event")]
            end
          else
            [400, j(error: "must open an event before closing it")]
          end
        end
      else
        [400, j(error: "state must be 'open' or 'closed'")]
      end
    end

    private

    def prev_opened?(uuid)
      ! DB[:billable_events].
        filter(entity_id_uuid: uuid, state: 1).
        count.
        zero?
    end

    def prev_closed?(eid)
      ! DB[:closed_events].
        filter(entity_id: eid).
        count.
        zero?
    end

    def delete_event(eid)
      s = DB[:billable_events].
        filter(entity_id_uuid: eid)
      s.first.tap {s.delete}
    end

    def open_event(args)
      DB[:billable_events].
        insert(provider_id: args[:provider_id],
                entity_id_uuid: Utils.validate_uuid(args[:entity_id_uuid]),
                rate_code_id: resolve_rc(args[:rate_code]),
                hid: args[:hid],
                qty: args[:qty],
                product_name: args[:product_name],
                description: args[:description],
                time: args[:time],
                created_at: Time.now,
                state: OPEN)
    end

    def close_event(open, args)
      DB[:closed_events].
        insert(provider_id: args[:provider_id],
                entity_id: Utils.validate_uuid(args[:entity_id_uuid]),
                rate_code_id: open[:rate_code_id],
                resource_id: open[:hid],
                qty: open[:qty],
                product_name: open[:product_name],
                description: open[:description],
                from: open[:time],
                to: args[:time],
                created_at: Time.now)
    end

    def resolve_rc(slug)
      DB[:rate_codes].filter(slug: slug).first[:id]
    end

    def valid_args?(args)
      missing_args(args).length.zero?
    end

    def missing_args(args)
      required_args(args[:state]) - args.reject {|k,v| v.nil?}.keys
    end

    def required_args(state)
      case state.to_s
      when "open"
        [:provider_id, :rate_code, :entity_id_uuid, :hid, :qty, :time, :state]
      when "close"
        [:provider_id, :entity_id_uuid, :state, :time]
      end
    end

    def j(hash)
      Yajl::Encoder.encode(hash)
    end

  end
end
