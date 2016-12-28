class AddSignedCustomFieldsToPayolaSubscription < ActiveRecord::Migration
  def change
    add_column :payola_subscriptions, :signed_custom_fields, :text
  end
end
