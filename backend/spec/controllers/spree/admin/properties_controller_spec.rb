# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::PropertiesController, type: :controller do
  stub_authorization!

  let(:property) { create(:property) }
  let(:properties) { create_list(:property, 3) }

  context "#index" do
    it "retrieves collection from stored properties" do
      get :index
      expect(assigns(:collection)).to eq(properties)
    end

    it "returns an empty collection when no properties are found" do
      Spree::Property.destroy_all
      get :index
      expect(assigns(:collection)).to be_empty
    end
  end
end
