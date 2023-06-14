# frozen_string_literal: true

require "view_component"
require "solidus_admin/container"
require "solidus_admin/importmap_reloader"

module SolidusAdmin
  class Engine < ::Rails::Engine
    isolate_namespace SolidusAdmin

    config.before_initialize do
      require "solidus_admin/configuration"
    end

    initializer "solidus_admin.importmap" do
      SolidusAdmin::Config.importmap_paths.each { |path| SolidusAdmin.importmap.draw(path) }
    end

    initializer "solidus_admin.importmap.reloader" do |app|
      ImportmapReloader.new.tap do |reloader|
        reloader.execute
        app.reloaders << reloader
        app.reloader.to_run { reloader.execute }
      end
    end

    initializer "solidus_admin.assets" do |app|
      app.config.assets.precompile += %w[solidus_admin_manifest.js]
    end

    initializer "solidus_admin.importmap.cache_sweeper" do |app|
      if app.config.importmap.sweep_cache
        SolidusAdmin.importmap.cache_sweeper(watches: SolidusAdmin::Config.importmap_cache_sweepers)

        ActiveSupport.on_load(:action_controller_base) do
          before_action { SolidusAdmin.importmap.cache_sweeper.execute_if_updated }
        end
      end
    end

    initializer "solidus_admin.importmap.assets" do |app|
      app.config.assets.paths << SolidusAdmin::Engine.root.join("app/javascript")
    end

    initializer "solidus_admin.main_nav_items_provider" do
      require "solidus_admin/system/providers/main_nav"

      Container.start("main_nav")
    end
  end
end
