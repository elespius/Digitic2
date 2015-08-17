module Spree
  module TaxonsHelper
    # Retrieves the collection of products to display when "previewing" a taxon.  This is abstracted into a helper so
    # that we can use configurations as well as make it easier for end users to override this determination.  One idea is
    # to show the most popular products for a particular taxon (that is an exercise left to the developer.)
    def taxon_preview(taxon, max=4)
      products = taxon.active_products.select(*selection_sql).limit(max)
      if (products.size < max)
        products_arel = Spree::Product.arel_table
        taxon.descendants.each do |taxon|
          to_get = max - products.length
          products += taxon.active_products.select(*selection_sql).where(products_arel[:id].not_in(products.map(&:id))).limit(to_get)
          break if products.size >= max
        end
      end
      products
    end

    private

    def selection_sql
      [
        Arel::Nodes::DistinctOn.new(Spree::Product.arel_table[:id]).to_sql,
        Spree::Product.arel_table[:*],
        Spree::Classification.arel_table[:position]
      ]
    end
  end
end
