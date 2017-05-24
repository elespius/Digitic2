module Spree
  # Represents a means of having a shipment delivered, such as FedEx or UPS.
  #
  class ShippingMethod < Spree::Base
    acts_as_paranoid
    include Spree::CalculatedAdjustments
    DISPLAY = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
      [:both, :front_end, :back_end],
      "Spree::ShippingMethod::DISPLAY is deprecated",
      Spree::Deprecation
    )

    has_many :store_shipping_methods, inverse_of: :shipping_method
    has_many :stores, through: :store_shipping_methods

    has_many :shipping_method_categories, dependent: :destroy
    has_many :shipping_categories, through: :shipping_method_categories
    has_many :shipping_rates, inverse_of: :shipping_method
    has_many :shipments, through: :shipping_rates
    has_many :cartons, inverse_of: :shipping_method

    has_many :shipping_method_zones
    has_many :zones, through: :shipping_method_zones

    belongs_to :tax_category, -> { with_deleted }, class_name: 'Spree::TaxCategory'
    has_many :shipping_method_stock_locations, dependent: :destroy, class_name: "Spree::ShippingMethodStockLocation"
    has_many :stock_locations, through: :shipping_method_stock_locations

    validates :name, presence: true

    validate :at_least_one_shipping_category

    # @param shipping_category_ids [Array<Integer>] ids of desired shipping categories
    # @return [ActiveRecord::Relation] shipping methods which are associated
    #   with all of the provided shipping categories
    def self.with_all_shipping_category_ids(shipping_category_ids)
      # Some extra care is needed with the having clause to ensure we are
      # counting distinct records of the join table. Otherwise a join could
      # cause this to return incorrect results.
      join_table = Spree::ShippingMethodCategory.arel_table
      having = join_table[:id].count(true).eq(shipping_category_ids.count)
      joins(:shipping_method_categories).
        where(spree_shipping_method_categories: { shipping_category_id: shipping_category_ids }).
        group('spree_shipping_methods.id').
        having(having)
    end

    # @param stock_location [Spree::StockLocation] stock location
    # @return [ActiveRecord::Relation] shipping methods which are available
    #   with the stock location or are marked available_to_all_stock_locations
    def self.available_in_stock_location(stock_location)
      smsl_table = Spree::ShippingMethodStockLocation.arel_table

      # We are searching for either a matching entry in the stock location join
      # table or available_to_all_stock_locations being true.
      # We need to use an outer join otherwise a shipping method with no
      # associated stock locations will be filtered out of the results. In
      # rails 5 this will be easy using .left_join and .or, but for now we must
      # use arel to achieve this.
      arel_join =
        arel_table.join(smsl_table, Arel::Nodes::OuterJoin).
        on(arel_table[:id].eq(smsl_table[:shipping_method_id])).
        join_sources
      arel_condition =
        arel_table[:available_to_all_stock_locations].eq(true).or(smsl_table[:stock_location_id].eq(stock_location.id))

      joins(arel_join).where(arel_condition).distinct
    end

    # @param address [Spree::Address] address to match against zones
    # @return [ActiveRecord::Relation] shipping methods which are associated
    #   with zones matching the provided address
    def self.available_for_address(address)
      joins(:zones).merge(Zone.for_address(address))
    end

    def self.available_for_store(store = nil)
      methods = ShippingMethod.arel_table
      store_methods = StoreShippingMethod.arel_table

      join_condition = methods.join(store_methods, Arel::Nodes::OuterJoin).
        on(methods[:id].eq(store_methods[:shipping_method_id])).
        join_sources

      conditions = [methods[:available_to_all_stores].eq(true)]
      conditions << store_methods[:store_id].eq(store.id) if store

      joins(join_condition).where(conditions.inject(&:or)).distinct
    end

    def include?(address)
      return false unless address
      zones.any? do |zone|
        zone.include?(address)
      end
    end

    def build_tracking_url(tracking)
      return if tracking.blank? || tracking_url.blank?
      tracking_url.gsub(/:tracking/, ERB::Util.url_encode(tracking)) # :url_encode exists in 1.8.7 through 2.1.0
    end

    def display_on
      if available_to_users?
        "both"
      else
        "back_end"
      end
    end
    deprecate display_on: :available_to_users?, deprecator: Spree::Deprecation

    def display_on=(value)
      self.available_to_users = (value != "back_end")
    end
    deprecate 'display_on=': :available_to_users=, deprecator: Spree::Deprecation

    # Some shipping methods are only meant to be set via backend
    def frontend?
      available_to_users?
    end
    deprecate frontend?: :available_to_users?, deprecator: Spree::Deprecation

    def available_to_all=(val)
      ActiveSupport::Deprecation.warn <<-EOS.squish, caller
        ShippingMethod#available_to_all= has been deprecated. The column has
        been renamed to available_to_all_stock_locations.
      EOS
      self.available_to_all_stock_locations = val
    end

    def available_to_all
      ActiveSupport::Deprecation.warn <<-EOS.squish, caller
        ShippingMethod#available_to_all has been deprecated. The column has
        been renamed to available_to_all_stock_locations.
      EOS
      available_to_all_stock_locations
    end
    alias_method :available_to_all?, :available_to_all

    private

    def at_least_one_shipping_category
      if shipping_categories.empty?
        errors[:base] << "You need to select at least one shipping category"
      end
    end
  end
end
