require 'spree/base'
module Spree
  class PromotionRuleUser < Spree::Base
    self.table_name = 'spree_promotion_rules_users'

    belongs_to :promotion_rule, class_name: 'Spree::PromotionRule'
    belongs_to :user, class_name: Spree::UserClassHandle.new
  end
end
