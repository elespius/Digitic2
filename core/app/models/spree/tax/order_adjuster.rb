module Spree
  module Tax
    # Add tax adjustments to all line items and shipments in an order
    class OrderAdjuster
      attr_reader :order

      include TaxHelpers

      # @param [Spree::Order] order to be adjusted
      def initialize(order)
        @order = order
      end

      # Creates tax adjustments for all taxable items (shipments and line items)
      # in the given order.
      def adjust!
        return unless order.tax_address

        (order.line_items + order.shipments).each do |item|
          ItemAdjuster.new(item, order_wide_options).adjust!
        end
      end

      private

      def order_wide_options
        {
          order_rates: order_rates,
          default_vat_rates: default_vat_rates
        }
      end
    end
  end
end
