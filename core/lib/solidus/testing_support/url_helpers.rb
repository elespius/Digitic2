module Spree
  module TestingSupport
    module UrlHelpers
      def spree
        Solidus::Core::Engine.routes.url_helpers
      end
    end
  end
end
