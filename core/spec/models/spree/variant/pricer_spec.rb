require 'spec_helper'

describe Spree::Variant::Pricer do
  let(:variant) { build_stubbed(:variant) }

  subject { described_class.new(variant) }

  it { is_expected.to respond_to(:variant) }
  it { is_expected.to respond_to(:price_for) }

  describe ".pricing_options_class" do
    it "returns the standard pricing options class" do
      expect(described_class.pricing_options_class).to eq(Spree::Variant::Pricer::PricingOptions)
    end
  end

  describe "#price_for(options)" do
    let(:variant) { create(:variant) }

    context "with the default currency" do
      let(:pricing_options) { described_class.pricing_options_class.new(currency: "USD") }

      it "returns the correct (default) price as a Spree::Money object" do
        expect(subject.price_for(pricing_options)).to eq(variant.default_price.money)
      end
    end

    context "with a different currency" do
      let(:pricing_options) { described_class.pricing_options_class.new(currency: "EUR") }

      context "when there is a price for that currency" do
        before do
          variant.prices.create(amount: 99.00, currency: "EUR")
        end

        it "returns the price in the correct currency as a Spree::Money object" do
          expect(subject.price_for(pricing_options)).to eq(Spree::Money.new(99.00, currency: "EUR"))
        end
      end

      context "when there is no price for that currency" do
        it "errors out with a Price Not Found error" do
          expect do
            subject.price_for(pricing_options)
          end.to raise_error(described_class::PriceNotFound)
        end
      end
    end
  end
end
