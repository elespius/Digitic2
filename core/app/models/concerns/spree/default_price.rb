module Spree
  module DefaultPrice
    extend ActiveSupport::Concern

    included do
      has_one :default_price,
        -> { where(currency: Spree::Config[:currency]).valid_before_now },
        class_name: 'Spree::Price',
        inverse_of: :variant,
        dependent: :destroy,
        autosave: true
    end

    def find_or_build_default_price
      default_price || build_default_price
    end

    delegate :display_price, :display_amount,
      :price, :price=, :currency, :currency=,
      to: :find_or_build_default_price

    def default_price
      Spree::Price.unscoped { super }
    end

    def has_default_price?
      !default_price.nil?
    end
  end
end
