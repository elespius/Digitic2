module Spree
  class UserAddress < ActiveRecord::Base
    belongs_to :user, class_name: UserClassHandle.new, foreign_key: "user_id"
    belongs_to :address, class_name: "Spree::Address"

    validates_uniqueness_of :address_id, scope: :user_id
    validates_uniqueness_of :user_id, conditions: -> { where(default: true) }, message: :default_address_exists, if: :default?

    scope :with_address_values, ->(address_attributes) do
      joins(:address).readonly(false).merge(
        Spree::Address.with_values(address_attributes)
      )
    end
  end
end
