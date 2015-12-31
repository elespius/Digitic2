module Spree
  class Classification < Solidus::Base
    self.table_name = 'spree_products_taxons'
    acts_as_list scope: :taxon
    belongs_to :product, class_name: "Solidus::Product", inverse_of: :classifications
    belongs_to :taxon, class_name: "Solidus::Taxon", inverse_of: :classifications, touch: true

    # For #3494
    validates_uniqueness_of :taxon_id, scope: :product_id, message: :already_linked
  end
end
