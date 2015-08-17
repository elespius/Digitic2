module Spree
  class Property < Spree::Base
    has_many :prototype_properties
    has_many :prototypes, through: :prototype_properties

    has_many :product_properties, dependent: :delete_all, inverse_of: :property
    has_many :products, through: :product_properties

    validates :name, :presentation, presence: true

    scope :sorted, -> { order(:name) }

    after_touch :touch_all_products

    private

    def touch_all_products
      products.update_all(updated_at: Time.current)
    end
  end
end
