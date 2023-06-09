# frozen_string_literal: true

require "dry/system"
require "dry/system/container"
require "dry/system/component"
require "view_component"
require "solidus_admin/loaders/host_overridable_constant"

module SolidusAdmin
  # Global registry for host-injectable components.
  #
  # We use this container to register all the components that can be
  # overridden by the host application.
  #
  # @api private
  class Container < Dry::System::Container
    configure do |config|
      config.root = Pathname(__FILE__).dirname.join("../..").realpath
      config.component_dirs.add("app/components/solidus_admin") do |dir|
        dir.loader = System::Loaders::HostOverridableConstant.method(:call).curry["components"]
        dir.namespaces.add nil, const: "solidus_admin", key: "components"
      end
    end

    # Returns all the registered components for a given namespace.
    #
    # @api private
    def self.within_namespace(namespace)
      keys.filter_map do
        _1.start_with?("#{namespace}#{config.namespace_separator}") && resolve(_1)
      end
    end
  end
end
