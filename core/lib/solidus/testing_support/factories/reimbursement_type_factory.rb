FactoryGirl.define do
  factory :reimbursement_type, class: Solidus::ReimbursementType do
    sequence(:name) { |n| "Reimbursement Type #{n}" }
    active true
    mutable true
  end
end
