# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAdmin::Sidebar::Component, type: :component do
  before do
    allow(vc_test_controller).to receive(:spree_current_user).and_return(build(:user))
    without_partial_double_verification do
      allow(vc_test_controller.spree).to receive(:admin_logout_path).and_return('/logout')
    end
  end

  it "renders the overview preview" do
    render_preview(:overview)
  end

  it "renders the solidus logo" do
    component = described_class.new(
      store: build(:store),
      items: []
    )

    render_inline(component)

    expect(page).to have_css("img[src*='solidus_admin/solidus_logo']")
  end

  it "renders the store link" do
    component = described_class.new(
      store: build(:store, url: "https://example.com"),
      items: []
    )

    render_inline(component)

    expect(page).to have_content("https://example.com")
  end

  it "renders the account nav component" do
    account_nav_component = mock_component do
      def call
        "account nav"
      end
    end
    component = described_class.new(
      store: build(:store),
      items: [],
      account_nav_component: account_nav_component
    )

    render_inline(component)

    expect(page).to have_content("account nav")
  end
end
