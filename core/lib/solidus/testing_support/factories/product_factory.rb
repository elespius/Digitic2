FactoryGirl.define do
  factory :base_product, class: Solidus::Product do
    sequence(:name) { |n| "Product ##{n} - #{Kernel.rand(9999)}" }
    description { generate(:random_description) }
    price 19.99
    cost_price 17.00
    sku { generate(:sku) }
    available_on { 1.year.ago }
    deleted_at nil
    shipping_category { |r| Solidus::ShippingCategory.first || r.association(:shipping_category) }

    # ensure stock item will be created for this products master
    before(:create) { create(:stock_location) if Solidus::StockLocation.count == 0 }

    factory :custom_product do
      name 'Custom Product'
      price 17.99

      tax_category { |r| Solidus::TaxCategory.first || r.association(:tax_category) }
    end

    factory :product do
      tax_category { |r| Solidus::TaxCategory.first || r.association(:tax_category) }

      factory :product_in_stock do
        after :create do |product|
          product.master.stock_items.first.adjust_count_on_hand(10)
        end
      end

      factory :product_with_option_types do
        after(:create) { |product| create(:product_option_type, product: product) }
      end
    end
  end
end
