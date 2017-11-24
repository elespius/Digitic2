# -*- encoding: utf-8 -*-
require_relative '../core/lib/spree/core/version.rb'

Gem::Specification.new do |gem|
  gem.author        = 'Solidus Team'
  gem.email         = 'contact@solidus.io'
  gem.homepage      = 'http://solidus.io/'
  gem.license       = 'BSD-3-Clause'

  gem.summary       = 'REST API for the Solidus e-commerce framework.'
  gem.description   = gem.summary

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "solidus_api"
  gem.require_paths = ["lib"]
  gem.version = Spree.solidus_version

  gem.required_ruby_version = '>= 2.2.2'
  gem.required_rubygems_version = '>= 1.8.23'

  gem.add_dependency 'solidus_core', gem.version
  gem.add_dependency 'responders'
  gem.add_dependency 'jbuilder', '~> 2.6'
  gem.add_dependency 'kaminari', '>= 0.17', '< 2.0'

  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'database_cleaner', '~> 1.3'
  gem.add_development_dependency 'factory_bot', '~> 4.8'
  gem.add_development_dependency 'rails-controller-testing'
  gem.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0.2'
  gem.add_development_dependency 'rspec-rails', '~> 3.6.0'
  gem.add_development_dependency 'rspec_junit_formatter'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'with_model'
end
