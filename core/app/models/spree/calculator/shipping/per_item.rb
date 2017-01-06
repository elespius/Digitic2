require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class PerItem < ShippingCalculator
      preference :amount, :decimal, default: 0
      preference :currency, :string, default: ->{ Spree::Config[:currency] }

      def compute_package(package)
        if package.order && preferred_currency.casecmp(package.order.currency).zero?
          compute_from_quantity(package.contents.sum(&:quantity))
        else
          BigDecimal.new(0)
        end
      end

      def compute_from_quantity(quantity)
        preferred_amount * quantity
      end
    end
  end
end
