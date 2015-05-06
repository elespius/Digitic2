require 'spec_helper'

describe Spree::Asset, :type => :model do
  describe "#viewable" do
    it "touches association", touching: true do
      product = create(:custom_product)
      asset = Spree::Asset.create! { |a| a.viewable = product.master }

      expect do
        asset.save
      end.to change { product.reload.updated_at }
    end
  end

  describe "#acts_as_list scope" do
    it "should start from first position for different viewables" do
      asset1 = Spree::Asset.create(viewable_type: 'Spree::Image', viewable_id: 1)
      asset2 = Spree::Asset.create(viewable_type: 'Spree::LineItem', viewable_id: 1)

      expect(asset1.position).to eq 1
      expect(asset2.position).to eq 1
    end
  end

end
