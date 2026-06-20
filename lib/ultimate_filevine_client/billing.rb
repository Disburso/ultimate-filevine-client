# frozen_string_literal: true

module UltimateFilevineClient
  # The billing facade, reached via {Client#billing}. Groups the billing
  # sub-resources under one namespace:
  #
  #   client.billing.invoices.list(project_id: 88)
  #   client.billing.transactions.create_payment(88, Date: "2026-07-01", Total: 500, Method: "Check")
  #   client.billing.funds.balance(88)
  #   client.billing.rate_schedules.list
  #
  # Built eagerly per {Client} (stateless sub-resources), so it is cheap to build
  # and safe to share across threads.
  class Billing
    # Sub-resource accessors -> their classes, built eagerly per client.
    SUBRESOURCES = {
      invoices: Resources::Billing::Invoices,
      items: Resources::Billing::Items,
      transactions: Resources::Billing::Transactions,
      funds: Resources::Billing::Funds,
      rate_schedules: Resources::Billing::RateSchedules,
      invoice_templates: Resources::Billing::InvoiceTemplates,
      codes: Resources::Billing::Codes,
      settings: Resources::Billing::Settings,
      fv_payments: Resources::Billing::FvPayments,
      timekeeper_classifications: Resources::Billing::TimekeeperClassifications
    }.freeze

    def initialize(client)
      @subresources = SUBRESOURCES.transform_values { |klass| klass.new(client) }
    end

    SUBRESOURCES.each_key do |name|
      define_method(name) { @subresources.fetch(name) }
    end
  end
end
