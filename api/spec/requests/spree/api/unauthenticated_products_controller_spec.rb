require 'shared_examples/protect_product_actions'
require 'spec_helper'

module Spree
  describe Spree::Api::ProductsController, type: :request do

    let!(:store) { create(:store) }
    let!(:product) { create(:product) }
    let(:attributes) { [:id, :name, :description, :price, :available_on, :slug, :meta_description, :meta_keywords, :taxon_ids] }

    context "without authentication" do
      before { Spree::Api::Config[:requires_authentication] = false }

      it "retrieves a list of products" do
        get spree.api_products_path
        expect(json_response["products"].first).to have_attributes(attributes)
        expect(json_response["count"]).to eq(1)
        expect(json_response["current_page"]).to eq(1)
        expect(json_response["pages"]).to eq(1)
      end

      it_behaves_like "modifying product actions are restricted"
    end
  end
end
