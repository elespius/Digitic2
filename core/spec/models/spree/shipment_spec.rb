require "spec_helper"
require "benchmark"

describe Spree::Shipment, :type => :model do
  let(:stock_location) { create(:stock_location) }
  let(:order) { create(:order_ready_to_ship, line_items_count: 1) }
  let(:shipping_method) { create(:shipping_method, name: "UPS") }
  let(:stock_location) { create(:stock_location) }
  let(:shipment) do
    order.shipments.create!(
      state: "pending",
      cost: 1,
      address: order.ship_address,
      inventory_units: order.inventory_units,
      shipping_rates: [
        Spree::ShippingRate.new(
          shipping_method: shipping_method,
          selected: true,
        ),
      ],
      stock_location: stock_location,
    )
  end

  let(:variant) { mock_model(Spree::Variant) }
  let(:line_item) { mock_model(Spree::LineItem, variant: variant) }

  describe "#determine_state" do
    it "returns canceled if order is canceled?" do
      allow(order).to receive_messages canceled?: true
      expect(shipment.determine_state(order)).to eq "canceled"
    end

    it "returns pending unless order.can_ship?" do
      allow(order).to receive_messages can_ship?: false
      expect(shipment.determine_state(order)).to eq "pending"
    end

    it "returns pending if backordered" do
      allow(shipment).to receive_messages inventory_units: [mock_model(Spree::InventoryUnit, backordered?: true)]
      expect(shipment.determine_state(order)).to eq "pending"
    end

    it "returns shipped when already shipped" do
      allow(shipment).to receive_messages state: "shipped"
      expect(shipment.determine_state(order)).to eq "shipped"
    end

    it "returns pending when unpaid" do
      allow(order).to receive_messages paid?: false
      expect(shipment.determine_state(order)).to eq "pending"
    end

    it "returns ready when paid" do
      allow(order).to receive_messages paid?: true
      expect(shipment.determine_state(order)).to eq "ready"
    end
  end

  context "display_amount" do
    it "retuns a Spree::Money" do
      shipment.cost = 21.22
      expect(shipment.display_amount).to eq(Spree::Money.new(21.22))
    end
  end

  context "display_final_price" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:final_price) { 21.22 }
      expect(shipment.display_final_price).to eq(Spree::Money.new(21.22))
    end
  end

  context "display_item_cost" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:item_cost) { 21.22 }
      expect(shipment.display_item_cost).to eq(Spree::Money.new(21.22))
    end
  end

  describe "#item_cost" do
    it "should equal line items final amount with tax" do
      shipment = create(:shipment, order: create(:order_with_totals))
      create :tax_adjustment, adjustable: shipment.order.line_items.first, order: shipment.order
      expect(shipment.item_cost).to eql(11.0)
    end
  end

  describe "#discounted_cost" do
    let(:shipment) { build(:shipment) }

    it "applies the promo to the cost" do
      shipment.cost = 10
      shipment.promo_total = -1

      expect(shipment.discounted_cost).to eq(9)
    end
  end

  describe "#tax_total" do
    let(:shipment) { build(:shipment) }
    subject { shipment.tax_total }

    context "with included taxes" do
      before do
        shipment.included_tax_total = 10
      end

      it { is_expected.to eq(10) }
    end

    context "without included taxes" do
      let(:shipment) { build(:shipment) }

      it { is_expected.to eq(0) }
    end
  end

  it "#tax_total with additional taxes" do
    shipment = Spree::Shipment.new
    expect(shipment.tax_total).to eq(0)
    shipment.additional_tax_total = 10
    expect(shipment.tax_total).to eq(10)
  end

  it "#final_price" do
    shipment = Spree::Shipment.new
    shipment.cost = 10
    shipment.adjustment_total = -2
    shipment.included_tax_total = 1
    expect(shipment.final_price).to eq(8)
  end

  context "manifest" do
    let(:order) { build(:order) }
    let(:variant) { create(:variant) }
    let!(:line_item) { order.contents.add variant }
    let!(:shipment) { order.create_proposed_shipments.first }

    it "returns variant expected" do
      expect(shipment.manifest.first.variant).to eq variant
    end

    context "variant was removed" do
      before { variant.destroy }

      it "still returns variant expected" do
        expect(shipment.manifest.first.variant).to eq variant
      end
    end
  end

  describe "shipping_rates" do
    let(:shipment) { create(:shipment) }
    let(:shipping_method1) { create(:shipping_method) }
    let(:shipping_method2) { create(:shipping_method) }
    let(:shipping_rates) { [
      Spree::ShippingRate.new(shipping_method: shipping_method1, cost: 10.00, selected: true),
      Spree::ShippingRate.new(shipping_method: shipping_method2, cost: 20.00)
    ] }

    it "returns shipping_method from selected shipping_rate" do
      shipment.shipping_rates.delete_all
      shipment.shipping_rates.create shipping_method: shipping_method1, cost: 10.00, selected: true
      expect(shipment.shipping_method).to eq shipping_method1
    end

    context "refresh_rates" do
      let(:mock_estimator) { double("estimator", shipping_rates: shipping_rates) }
      before { allow(shipment).to receive(:can_get_rates?){ true } }

      it "should request new rates, and maintain shipping_method selection" do
        expect(Spree::Stock::Estimator).to receive(:new).with(shipment.order).and_return(mock_estimator)
        allow(shipment).to receive_messages(shipping_method: shipping_method2)

        expect(shipment.refresh_rates).to eq(shipping_rates)
        expect(shipment.reload.selected_shipping_rate.shipping_method_id).to eq(shipping_method2.id)
      end

      it "should handle no shipping_method selection" do
        expect(Spree::Stock::Estimator).to receive(:new).with(shipment.order).and_return(mock_estimator)
        allow(shipment).to receive_messages(shipping_method: nil)
        expect(shipment.refresh_rates).to eq(shipping_rates)
        expect(shipment.reload.selected_shipping_rate).not_to be_nil
      end

      it "should not refresh if shipment is shipped" do
        expect(Spree::Stock::Estimator).not_to receive(:new)
        shipment.shipping_rates.delete_all # FIXME
        allow(shipment).to receive_messages(shipped?: true)
        expect(shipment.refresh_rates).to eq([])
      end

      it "can't get rates without a shipping address" do
        shipment.order(ship_address: nil)
        expect(shipment.refresh_rates).to eq([])
      end

      describe "#to_package" do
        let(:inventory_units) do
          [build(:inventory_unit, line_item: line_item, variant: variant, state: "on_hand"),
           build(:inventory_unit, line_item: line_item, variant: variant, state: "backordered")]
        end

        before do
          allow(shipment).to receive(:inventory_units) { inventory_units }
          allow(inventory_units).to receive_message_chain(:includes, :joins).and_return inventory_units
        end

        it "should use symbols for states when adding contents to package" do
          package = shipment.to_package
          expect(package.on_hand.count).to eq 1
          expect(package.backordered.count).to eq 1
        end
      end
    end
  end

  describe "#update!" do
    shared_examples_for "immutable once shipped" do
      it "should remain in shipped state once shipped" do
        shipment.state = "shipped"
        expect(shipment).to receive(:update_columns).with(state: "shipped", updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    shared_examples_for "pending if backordered" do
      it "should have a state of pending if backordered" do
        allow(shipment).to receive_messages(inventory_units: [mock_model(Spree::InventoryUnit, backordered?: true)])
        expect(shipment).to receive(:update_columns).with(state: "pending", updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order cannot ship" do
      before { allow(order).to receive_messages can_ship?: false }

      it "should result in a 'pending' state" do
        expect(shipment).to receive(:update_columns).with(state: "pending", updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order is paid" do
      before { allow(order).to receive_messages paid?: true }

      it "should result in a 'ready' state" do
        expect(shipment).to receive(:update_columns).with(state: "ready", updated_at: kind_of(Time))
        shipment.update!(order)
      end
      it_should_behave_like "immutable once shipped"
      it_should_behave_like "pending if backordered"
    end

    context "when order has balance due" do
      before { allow(order).to receive_messages paid?: false }

      it "should result in a 'pending' state" do
        shipment.state = "ready"
        expect(shipment).to receive(:update_columns).with(state: "pending", updated_at: kind_of(Time))
        shipment.update!(order)
      end
      it_should_behave_like "immutable once shipped"
      it_should_behave_like "pending if backordered"
    end

    context "when order has a credit owed" do
      before do
        allow(order).to receive_messages payment_state: "credit_owed", paid?: true
      end

      it "should result in a 'ready' state" do
        shipment.state = "pending"
        expect(shipment).to receive(:update_columns).with(state: "ready", updated_at: kind_of(Time))
        shipment.update!(order)
      end

      it_should_behave_like "immutable once shipped"
      it_should_behave_like "pending if backordered"
    end

    context "when shipment state changes to shipped" do
      it "should call after_ship" do
        shipment.state = "pending"
        allow(shipment).to receive_messages(determine_state: "shipped")
        expect(shipment).to receive(:after_ship)
        expect(shipment).to receive(:update_columns).with(state: "shipped", updated_at: kind_of(Time))
        shipment.update!(order)
      end

      # Regression test for #4347
      context "with adjustments" do
        before do
          shipment.adjustments << Spree::Adjustment.create(order: order, label: "Label", amount: 5)
        end

        it "transitions to shipped" do
          shipment.update_column(:state, "ready")
          expect { shipment.ship! }.not_to raise_error
        end
      end
    end
  end

  context "when order is completed" do
    after { Spree::Config.set track_inventory_levels: true }

    before do
      allow(order).to receive_messages completed?: true
      allow(order).to receive_messages canceled?: false
    end

    context "with inventory tracking" do
      before { Spree::Config.set track_inventory_levels: true }

      it "should validate with inventory" do
        shipment.inventory_units = [create(:inventory_unit)]
        expect(shipment.valid?).to be true
      end
    end

    context "without inventory tracking" do
      before { Spree::Config.set track_inventory_levels: false }

      it "should validate with no inventory" do
        expect(shipment.valid?).to be true
      end
    end
  end

  describe "cancel" do
    it "cancels the shipment" do
      allow(shipment.order).to receive(:update!)
      shipment.state = "pending"
      expect(shipment).to receive(:after_cancel)
      shipment.cancel!

      expect(shipment.state).to eq "canceled"
    end

    it "restocks the items" do
      variant = shipment.inventory_units.first.variant
      shipment.stock_location = mock_model(Spree::StockLocation)
      expect(shipment.stock_location).to receive(:restock).with(variant, 1, shipment)
      shipment.after_cancel
    end

    context "with backordered inventory units" do
      let(:order) { build(:order) }
      let(:variant) { create(:variant) }
      let(:other_order) { build(:order) }
      let(:shipment) { order.shipments.first }

      before do
        order.contents.add variant
        order.create_proposed_shipments

        other_order.contents.add variant
        other_order.create_proposed_shipments
      end

      it "doesn't fill backorders when restocking inventory units" do
        expect(shipment.inventory_units.count).to eq 1
        expect(shipment.inventory_units.first).to be_backordered

        other_shipment = other_order.shipments.first
        expect(other_shipment.inventory_units.count).to eq 1
        expect(other_shipment.inventory_units.first).to be_backordered

        expect {
          shipment.cancel!
        }.not_to change { other_shipment.inventory_units.first.state }
      end
    end
  end

  context "resume" do
    let(:inventory_unit) { create(:inventory_unit) }

    it "will determine new state based on order" do
      allow(shipment.order).to receive(:update!)

      shipment.state = "canceled"
      expect(shipment).to receive(:determine_state).and_return(:ready)
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      expect(shipment.state).to eq "ready"
    end

    it "unstocks them items" do
      variant = shipment.inventory_units.first.variant
      shipment.stock_location = mock_model(Spree::StockLocation)
      expect(shipment.stock_location).to receive(:unstock).with(variant, 1, shipment)
      shipment.after_resume
    end

    it "will determine new state based on order" do
      allow(shipment.order).to receive(:update!)

      shipment.state = "canceled"
      expect(shipment).to receive(:determine_state).twice.and_return("ready")
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      # Shipment is pending because order is already paid
      expect(shipment.state).to eq "pending"
    end
  end

  context "with a selected shipping rate" do
    let(:shipment) { create(:shipment) }

    before do
      allow(shipment).to receive_message_chain :selected_shipping_rate, cost: 5
    end

    it "updates shipment totals" do
      shipment.update_amounts
      expect(shipment.reload.cost).to eq(5)
    end

    it "factors in additional adjustments to adjustment total" do
      shipment.adjustments.create!(
        order:    order,
        label:    "Additional",
        amount:   5,
        included: false,
        state:    "closed"
      )
      shipment.update_amounts
      expect(shipment.reload.adjustment_total).to eq(5)
    end

    it "does not factor in included adjustments to adjustment total" do
      shipment.adjustments.create!(
        order:    order,
        label:    "Included",
        amount:   5,
        included: true,
        state:    "closed"
      )
      shipment.update_amounts
      expect(shipment.reload.adjustment_total).to eq(0)
    end
  end

  context "changes shipping rate via general update" do
    let(:order) do
      Spree::Order.create(
        payment_total: 100, payment_state: "paid", total: 100, item_total: 100
      )
    end

    let(:shipment) { create(:shipment, order_id: order.id) }
    let(:shipping_rate) { create(:shipping_rate, shipment_id: shipment.id, cost: 10) }

    before do
      shipment.update_attributes_and_order selected_shipping_rate_id: shipping_rate.id
    end

    it "updates everything around order shipment total and state" do
      expect(shipment.cost.to_f).to eq 10
      expect(shipment.state).to eq "pending"
      expect(shipment.order.total.to_f).to eq 110
      expect(shipment.order.payment_state).to eq "balance_due"
    end
  end

  context "after_save" do
    context "line item changes" do
      before do
        shipment.cost = shipment.cost + 10
      end

      it "triggers adjustment total recalculation" do
        expect(shipment).to receive(:recalculate_adjustments)
        shipment.save
      end

      it "does not trigger adjustment recalculation if shipment has shipped" do
        shipment.state = "shipped"
        expect(shipment).not_to receive(:recalculate_adjustments)
        shipment.save
      end
    end

    context "line item does not change" do
      it "does not trigger adjustment total recalculation" do
        expect(shipment).not_to receive(:recalculate_adjustments)
        shipment.save
      end
    end
  end

  describe "#currency" do
    it "returns the order currency" do
      expect(shipment.currency).to eq(order.currency)
    end
  end

  context "nil costs" do
    it "sets cost to 0" do
      shipment = Spree::Shipment.new
      shipment.valid?
      expect(shipment.cost).to eq 0
    end
  end

  describe "#ship" do
    context "when the shipment is canceled" do
      let(:address){ build(:address) }
      let(:order){ create(:order_with_line_items, ship_address: address) }
      let(:shipment_with_inventory_units) { create(:shipment, order: order, address: address, state: "canceled") }

      subject { shipment_with_inventory_units.ship! }

      it "unstocks them items" do
        allow(shipment_with_inventory_units.stock_location).to receive(:unstock).with(an_instance_of(Spree::Variant), 1, shipment_with_inventory_units)
        subject
      end
    end

    ["ready", "canceled"].each do |state|
      context "from #{state}" do
        before do
          allow(order).to receive(:update!)
          allow(shipment).to receive_messages(require_inventory: false, update_order: true, state: state)
        end

        it "should call fulfill_order_with_stock_location" do
          expect(Spree::OrderStockLocation).to(
            receive(:fulfill_for_order_with_stock_location).
            with(order, stock_location)
          )
          shipment.ship!
        end

        it "finalizes adjustments" do
          shipment.adjustments.each do |adjustment|
            expect(adjustment).to receive(:finalize!)
          end
          shipment.ship!
        end
      end
    end
  end

  describe "#ready" do
    # Regression test for #2040
    it "cannot ready a shipment for an order if the order is unpaid" do
      expect(order).to receive_messages(paid?: false)
      expect(shipment).not_to be_can_ready
    end
  end

  describe "#tracking_url" do
    subject { shipment.tracking_url }

    before do
      shipping_method.update!(tracking_url: "https://example.com/:tracking")
      shipment.tracking = "1Z12345"
    end

    it "uses shipping method to determine url" do
      is_expected.to eq("https://example.com/1Z12345")
    end
  end

  context "set up new inventory units" do
    let(:variant) { double("Variant", id: 9) }
    let(:inventory_units) { double }
    let(:params) do
      { variant_id: variant.id, state: "on_hand", order_id: order.id, line_item_id: line_item.id }
    end

    before { allow(shipment).to receive_messages inventory_units: inventory_units }

    it "associates variant and order" do
      expect(inventory_units).to receive(:create).with(params)
      unit = shipment.set_up_inventory("on_hand", variant, order, line_item)
    end
  end

  # Regression test for #3349
  describe "#destroy" do
    it "destroys linked shipping_rates" do
      reflection = Spree::Shipment.reflect_on_association(:shipping_rates)
      expect(reflection.options[:dependent]).to be(:delete_all)
    end
  end

  # Regression test for #4072 (kinda)
  # The need for this was discovered in the research for #4702
  context "state changes" do
    before do
      # Must be stubbed so transition can succeed
      allow(order).to receive_messages :paid? => true
    end

    it "are logged to the database" do
      expect(shipment.state_changes).to be_empty
      expect(shipment.ready!).to be true
      expect(shipment.state_changes.count).to eq(1)
      state_change = shipment.state_changes.first
      expect(state_change.previous_state).to eq("pending")
      expect(state_change.next_state).to eq("ready")
    end
  end

  context "don't require shipment" do
    let(:stock_location) { build(:stock_location, fulfillable: false)}
    let(:unshippable_shipment) do
      create(
        :shipment,
        address: create(:address),
        stock_location: stock_location,
        inventory_units: [build(:inventory_unit)],
      )
    end

    before { allow(order).to receive(:paid?).and_return true }

    it "proceeds automatically to shipped state" do
      unshippable_shipment.ready!
      expect(unshippable_shipment.state).to eq("shipped")
    end

    it "does not send a confirmation email" do
      expect(unshippable_shipment).to_not receive(:send_shipment_email)
      unshippable_shipment.ready!
      unshippable_shipment.inventory_units.each do |unit|
        expect(unit.state).to eq("shipped")
      end
    end
  end

  context "with a backordered inventory_unit" do
    it "is backordered" do
      shipment.inventory_units = [
        build(:inventory_unit, state: "backordered", shipment: nil),
        build(:inventory_unit, state: "shipped", shipment: nil),
      ]
      expect(shipment).to be_backordered
    end
  end

  describe "#final_price_with_items" do
    it "should return the total item and shipping cost" do
      expect(shipment.final_price_with_items).to eq(shipment.final_price + order.line_items.to_a.sum(&:price))
    end
  end
end
