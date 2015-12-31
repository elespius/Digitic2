module Solidus
  module PermissionSets
    class SuperUser < PermissionSets::Base
      def activate!
        can :manage, :all
      end
    end
  end
end
