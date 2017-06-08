require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatRate < Calculator
    preference :amount, :decimal, default: 0
    preference :currency, :string, default: ->{ Spree::Config[:currency] }

    def compute(object = nil)
      if object && preferred_currency.casecmp(object.currency).zero?
        preferred_amount
      else
        BigDecimal.new(0)
      end
    end
  end
end
