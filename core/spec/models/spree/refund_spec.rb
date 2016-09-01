require 'rails_helper'

RSpec.describe Spree::Refund, type: :model do
  let(:amount) { 100.0 }
  let(:amount_in_cents) { amount * 100 }

  let(:authorization) { generate(:refund_transaction_id) }

  let(:payment) { create(:payment, amount: payment_amount, payment_method: payment_method) }
  let(:payment_amount) { amount * 2 }
  let(:payment_method) { create(:credit_card_payment_method) }

  let(:refund_reason) { create(:refund_reason) }

  let(:gateway_response) {
    ActiveMerchant::Billing::Response.new(
      gateway_response_success,
      gateway_response_message,
      gateway_response_params,
      gateway_response_options
    )
  }
  let(:gateway_response_success) { true }
  let(:gateway_response_message) { "" }
  let(:gateway_response_params) { {} }
  let(:gateway_response_options) { {} }

  before do
    allow(payment.payment_method)
      .to receive(:credit)
      .with(amount_in_cents, payment.source, payment.transaction_id, { originator: an_instance_of(Spree::Refund) })
      .and_return(gateway_response)
  end

  describe 'create' do
    subject { create(:refund, payment: payment, amount: amount, reason: refund_reason, transaction_id: nil) }

    it "creates a refund record" do
      expect{ subject }.to change { Spree::Refund.count }.by(1)
    end

    it "saves the amount" do
      expect(subject.reload.amount).to eq amount
      expect(subject.money).to be_a(Spree::Money)
    end

    it "does not attempt to process a transaction" do
      expect(subject.transaction_id).to be_nil
    end
  end

  describe "#perform!" do
    subject do
      refund = Spree::Refund.create!(
        payment: payment,
        amount: amount,
        reason: refund_reason,
        transaction_id: transaction_id
      )
      refund.perform!
      refund
    end

    context "when transaction_id exists" do
      let(:transaction_id) { "12kfjas0" }

      it "maintains the transaction id" do
        expect(subject.reload.transaction_id).to eq transaction_id
      end

      it "does not attempt to process a transaction" do
        expect(payment.payment_method).not_to receive(:credit)
        subject
      end
    end

    context "when transaction_id is nil" do
      let(:transaction_id) { nil }

      context "processing is successful" do
        let(:gateway_response_options) { { authorization: authorization } }

        it 'should create a refund' do
          expect{ subject }.to change{ Spree::Refund.count }.by(1)
        end

        it 'returns the newly created refund' do
          expect(subject).to be_a(Spree::Refund)
        end

        it 'should save the returned authorization value' do
          expect(subject.reload.transaction_id).to eq authorization
        end

        it 'should save the passed amount as the refund amount' do
          expect(subject.amount).to eq amount
        end

        it 'should create a log entry' do
          expect(subject.log_entries).to be_present
        end

        it "attempts to process a transaction" do
          expect(payment.payment_method).to receive(:credit).once
          subject
        end

        it 'should update the payment total' do
          expect(payment.order.updater).to receive(:update)
          subject
        end
      end

      context "processing fails" do
        let(:gateway_response_success) { false }
        let(:gateway_response_message) { "failure message" }

        it 'should raise error and not create a refund' do
          expect do
            expect { subject }.to raise_error(Spree::Core::GatewayError, gateway_response_message)
          end.to change{ Spree::Refund.count }
        end
      end

      context 'without payment profiles supported' do
        let(:gateway_response_options) { { authorization: authorization } }
        before do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { false }
        end

        it 'should not supply the payment source' do
          expect(payment.payment_method)
            .to receive(:credit)
            .with(amount * 100, payment.transaction_id, { originator: an_instance_of(Spree::Refund) })
            .and_return(gateway_response)

          subject
        end
      end

      context 'with payment profiles supported' do
        let(:gateway_response_options) { { authorization: authorization } }
        before do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { true }
        end

        it 'should supply the payment source' do
          expect(payment.payment_method)
            .to receive(:credit)
            .with(amount_in_cents, payment.source, payment.transaction_id, { originator: an_instance_of(Spree::Refund) })
            .and_return(gateway_response)

          subject
        end
      end

      context 'with an activemerchant gateway connection error' do
        before do
          expect(payment.payment_method)
            .to receive(:credit)
            .with(amount_in_cents, payment.source, payment.transaction_id, { originator: an_instance_of(Spree::Refund) })
            .and_raise(ActiveMerchant::ConnectionError.new("foo", nil))
        end

        it 'raises Spree::Core::GatewayError' do
          expect { subject }.to raise_error(Spree::Core::GatewayError, I18n.t('spree.unable_to_connect_to_gateway'))
        end
      end

      context 'with amount too large' do
        let(:payment_amount) { 10 }
        let(:amount) { payment_amount * 2 }

        it 'is invalid' do
          expect { subject }.to raise_error { |error|
            expect(error).to be_a(ActiveRecord::RecordInvalid)
            expect(error.record.errors.full_messages).to eq ["Amount #{I18n.t('activerecord.errors.models.spree/refund.attributes.amount.greater_than_allowed')}"]
          }
        end
      end
    end

    context 'when payment is not present' do
      let(:refund) { build(:refund, payment: nil) }

      it 'returns a validation error' do
        expect { refund.save! }.to raise_error 'Validation failed: Payment can\'t be blank'
      end
    end
  end

  describe 'total_amount_reimbursed_for' do
    let(:customer_return) { reimbursement.customer_return }
    let(:reimbursement) { create(:reimbursement) }
    let!(:default_refund_reason) { Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false) }

    subject { Spree::Refund.total_amount_reimbursed_for(reimbursement) }

    context 'with reimbursements performed' do
      before { reimbursement.perform! }

      it 'returns the total amount' do
        amount = Spree::Refund.total_amount_reimbursed_for(reimbursement)
        expect(amount).to be > 0
        expect(amount).to eq reimbursement.total
      end
    end

    context 'without reimbursements performed' do
      it 'returns zero' do
        amount = Spree::Refund.total_amount_reimbursed_for(reimbursement)
        expect(amount).to eq 0
      end
    end
  end
end
