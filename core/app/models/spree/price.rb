module Spree
  class Price < Spree::Base
    acts_as_paranoid

    MAXIMUM_AMOUNT = BigDecimal('99_999_999.99')

    belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant', touch: true
    before_save :valid_from_today!, if: -> { valid_from.blank? }

    validate :check_price
    validates :amount, allow_nil: true, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: MAXIMUM_AMOUNT
    }

    scope :latest_valid_from_first, -> { order(valid_from: :desc) }
    scope :valid_before, -> (date) { where("#{Spree::Price.table_name}.valid_from <= ?", date) }
    scope :valid_before_now, -> { valid_before(Time.current) }

    after_save :set_default_price

    extend DisplayMoney
    money_methods :amount, :price

    self.whitelisted_ransackable_attributes = ['amount']

    # @return [Spree::Money] this price as a Spree::Money object
    def money
      Spree::Money.new(amount || 0, { currency: currency })
    end

    # An alias for #amount
    def price
      amount
    end

    # Sets this price's amount to a new value, parsing it if the new value is
    # a string.
    #
    # @param price [String, #to_d] a new amount
    def price=(price)
      self[:amount] = Spree::LocalizedNumber.parse(price)
    end

    private

    def valid_from_today!
      self.valid_from = Time.current
    end

    def check_price
      self.currency ||= Spree::Config[:currency]
    end

    def set_default_price
      if is_default?
        other_default_prices = variant.prices.where(currency: self.currency, is_default: true).where.not(id: id)
        other_default_prices.update_all(is_default: false)
      end
    end
  end
end
