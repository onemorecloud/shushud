require File.expand_path('../../../lib/shushu', __FILE__)

jan = Time.utc(2011,1)
feb = Time.utc(2011,2)

hid = "app123@heroku.com"
provider = Provider.create :name => "shushu@heroku.com", :token => "secret"
payment_method = PaymentMethod.create
account = Account.create :payment_method_id => payment_method.id

res_own_entity_id = SecureRandom.uuid
ResourceOwnershipService.activate(account.id, hid, jan, res_own_entity_id)

act_own_entity_id = SecureRandom.uuid
AccountOwnershipService.activate(payment_method.id, account.id, jan, act_own_entity_id)

RateCodeService.create(
  :provider_id        => provider.id,
  :slug               => "RT01",
  :rate               => 5,
  :product_group      => "dyno",
  :product_name       => "web"
)

SecureRandom.uuid.tap do |eid|
  BillableEventService.handle_new_event(
    :provider_id    => provider.id,
    :rate_code_slug => "RT01",
    :hid            => hid,
    :entity_id      => eid,
    :qty            => 1,
    :time           => jan,
    :state          => BillableEvent::Open
  )
  BillableEventService.handle_new_event(
    :provider_id    => provider.id,
    :rate_code_slug => "RT01",
    :hid            => hid,
    :entity_id      => eid,
    :qty            => 1,
    :time           => feb,
    :state          => BillableEvent::Close
  )
end

puts(<<-EOD)
\n\n
\t account: #{account.id}
\t payment_method: #{payment_method.id}
\n
\t select * from invoice(#{payment_method.id}, '#{jan.iso8601}', '#{feb.iso8601}');
\n
EOD