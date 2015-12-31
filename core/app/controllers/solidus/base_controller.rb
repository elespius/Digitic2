require 'cancan'
require_dependency 'spree/core/controller_helpers/strong_parameters'

class Solidus::BaseController < ApplicationController
  include Solidus::Core::ControllerHelpers::Auth
  include Solidus::Core::ControllerHelpers::RespondWith
  include Solidus::Core::ControllerHelpers::Common
  include Solidus::Core::ControllerHelpers::PaymentParameters
  include Solidus::Core::ControllerHelpers::Search
  include Solidus::Core::ControllerHelpers::Store
  include Solidus::Core::ControllerHelpers::StrongParameters

  respond_to :html
end
