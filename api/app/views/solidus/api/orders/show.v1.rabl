object @order
extends "solidus/api/orders/order"

child :available_payment_methods => :payment_methods do
  attributes :id, :name, :method_type
end

child :billing_address => :bill_address do
  extends "solidus/api/addresses/show"
end

child :shipping_address => :ship_address do
  extends "solidus/api/addresses/show"
end

child :line_items => :line_items do
  extends "solidus/api/line_items/show"
end

child :payments => :payments do
  attributes *payment_attributes

  child :payment_method => :payment_method do
    attributes :id, :name
  end

  child :source => :source do
    attributes *payment_source_attributes
    if @current_user_roles.include?('admin')
      attributes *(payment_source_attributes + [:gateway_customer_profile_id, :gateway_payment_profile_id])
    else
      attributes *payment_source_attributes
    end
  end
end

child :shipments => :shipments do
  extends "solidus/api/shipments/small"
end

child :adjustments => :adjustments do
  extends "solidus/api/adjustments/show"
end

# Necessary for backend's order interface
node :permissions do
  { can_update: current_ability.can?(:update, root_object) }
end

child :valid_credit_cards => :credit_cards do
  extends "solidus/api/credit_cards/show"
end
