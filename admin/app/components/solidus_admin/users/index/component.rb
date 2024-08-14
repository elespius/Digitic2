# frozen_string_literal: true

class SolidusAdmin::Users::Index::Component < SolidusAdmin::UsersAndRoles::Component
  def model_class
    Spree.user_class
  end

  def search_key
    :email_cont
  end

  def search_url
    solidus_admin.users_path
  end

  def row_url(user)
    spree.admin_user_path(user)
  end

  def page_actions
    render component("ui/button").new(
      tag: :a,
      text: t('.add'),
      href: spree.new_admin_user_path,
      icon: "add-line",
    )
  end

  def batch_actions
    [
      {
        label: t('.batch_actions.delete'),
        action: solidus_admin.users_path,
        method: :delete,
        icon: 'delete-bin-7-line',
      },
    ]
  end

  def scopes
    [
      { name: :customers, label: t('.scopes.customers'), default: true },
      { name: :admin, label: t('.scopes.admin') },
      { name: :with_orders, label: t('.scopes.with_orders') },
      { name: :without_orders, label: t('.scopes.without_orders') },
      { name: :all, label: t('.scopes.all') },
    ]
  end

  def filters
    [
      {
        label: Spree::Role.model_name.human.pluralize,
        attribute: "spree_roles_id",
        predicate: "in",
        options: Spree::Role.pluck(:name, :id)
      }
    ]
  end

  def columns
    [
      {
        header: :email,
        data: :email,
      },
      {
        header: :roles,
        data: ->(user) do
          roles = user.spree_roles.presence || [Spree::Role.new(name: 'customer')]
          safe_join(roles.map {
            color =
              case _1.name
              when 'admin' then :blue
              when 'customer' then :green
              else :graphite_light
              end
            render component('ui/badge').new(name: _1.name, color: color)
          })
        end,
      },
      {
        header: :order_count,
        data: ->(user) { user.order_count },
      },
      {
        header: :lifetime_value,
        data: -> { _1.display_lifetime_value.to_html },
      },
      {
        header: :created_at,
        data: ->(user) { l(user.created_at.to_date, format: :long) },
      },
    ]
  end
end
