require 'spec_helper'

describe Solidus::Stock::ShippingRateSelector do
  describe '#sort' do
    it 'sorts by increasing cost' do
      cheapest_shipping_rate = Solidus::ShippingRate.new(cost: 1.00)
      middle_shipping_rate = Solidus::ShippingRate.new(cost: 5.00)
      expensive_shipping_rate = Solidus::ShippingRate.new(cost: 42.00)
      shipping_rates = [expensive_shipping_rate, middle_shipping_rate, cheapest_shipping_rate]

      sorter = Solidus::Stock::ShippingRateSelector.new(shipping_rates)

      expect(sorter.find_default).to eq(cheapest_shipping_rate)
    end
  end
end
