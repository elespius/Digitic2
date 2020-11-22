# frozen_string_literal: true

if ENV["COVERAGE"]
  require 'simplecov'
  if ENV["COVERAGE_DIR"]
    SimpleCov.coverage_dir(ENV["COVERAGE_DIR"])
  end
  SimpleCov.command_name('solidus:core')
  SimpleCov.merge_timeout(3600)
  SimpleCov.start('rails')
end

=begin
require 'rspec/core'

require 'spree/testing_support/partial_double_verification'
require 'spree/testing_support/preferences'
require 'spree/config'
require 'with_model'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Spree::TestingSupport::Preferences
  config.extend WithModel

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "./spec/examples.txt"

  config.order = :random

  Kernel.srand config.seed
end
=end
