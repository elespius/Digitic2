class AddExpiresAtToSpreeStoreCredits < ActiveRecord::Migration[5.0]
  def change
    add_column :spree_store_credits, :expires_at, :datetime
  end
end
