module ShushuHelpers

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
    }.merge(opts))
  end

  def build_account(opts={})
    Account.create(opts)
  end

  def build_payment_method(opts={})
    PaymentMethod.create(opts)
  end

  def build_resource_ownership_record(opts={})
    ResourceOwnershipRecord.create({
      :hid => "12345",
      :time => Time.now,
      :state => ResourceOwnershipRecord::Active
    }.merge(opts))
  end

  def build_act_own(account_id, payment_method_id, entity_id, state, time)
    AccountOwnershipRecord.create(
      :account_id        => account_id,
      :payment_method_id => payment_method_id,
      :entity_id          => entity_id,
      :state             => state,
      :time              => time
    )
  end

  def build_res_own(account_id, hid, entity_id, state, time)
    ResourceOwnershipRecord.create(
      :account_id => account_id,
      :hid        => hid,
      :entity_id   => entity_id,
      :state      => state,
      :time       => time
    )
  end

  def build_billable_event(hid, entity_id, state, time)
    BillableEvent.create(
      :hid => hid,
      :entity_id => entity_id,
      :state => state,
      :time => time
    )
  end

  def build_receivable(pmid, amount, period_start, period_end)
    Receivable.create(
      :init_payment_method_id => pmid,
      :amount                 => amount,
      :period_start           => period_start,
      :period_end             => period_end
    )
  end

  def build_attempt(recid, pmid, wait_until, rtry)
    PaymentAttemptRecord.create(
      :payment_method_id => pmid,
      :receivable_id     => recid,
      :wait_until        => wait_until,
      :retry             => rtry
    )
  end

end
