FactoryGirl.define do
  factory :image, class: Solidus::Image do
    attachment { File.new(Solidus::Core::Engine.root + 'spec/fixtures/thinking-cat.jpg') }
  end
end
