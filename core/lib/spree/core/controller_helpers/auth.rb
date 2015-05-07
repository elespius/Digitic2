module Spree
  module Core
    module ControllerHelpers
      module Auth
        extend ActiveSupport::Concern

        mattr_accessor(:login_redirector) { Spree::Core::ControllerHelpers::LoginRedirector }

        included do
          include Spree::Core::ControllerHelpers::Auth.login_redirector

          before_filter :set_guest_token
          helper_method :try_spree_current_user

          rescue_from CanCan::AccessDenied do |exception|
            redirect_unauthorized_access
          end
        end

        # Needs to be overriden so that we use Spree's Ability rather than anyone else's.
        def current_ability
          @current_ability ||= Spree::Ability.new(try_spree_current_user)
        end

        def redirect_back_or_default(default)
          redirect_to(session["spree_user_return_to"] || default)
          session["spree_user_return_to"] = nil
        end

        def set_guest_token
          unless cookies.signed[:guest_token].present?
            cookies.permanent.signed[:guest_token] = SecureRandom.urlsafe_base64(nil, false)
          end
        end

        def store_location
          # disallow return to login, logout, signup pages
          authentication_routes = [:spree_signup_path, :spree_login_path, :spree_logout_path]
          disallowed_urls = []
          authentication_routes.each do |route|
            if respond_to?(route)
              disallowed_urls << send(route)
            end
          end

          disallowed_urls.map!{ |url| url[/\/\w+$/] }
          unless disallowed_urls.include?(request.fullpath)
            session['spree_user_return_to'] = request.fullpath.gsub('//', '/')
          end
        end

        # proxy method to *possible* spree_current_user method
        # Authentication extensions (such as spree_auth_devise) are meant to provide spree_current_user
        def try_spree_current_user
          # This one will be defined by apps looking to hook into Spree
          # As per authentication_helpers.rb
          if respond_to?(:spree_current_user)
            spree_current_user
          # This one will be defined by Devise
          elsif respond_to?(:current_spree_user)
            current_spree_user
          else
            nil
          end
        end

      end
    end
  end
end
