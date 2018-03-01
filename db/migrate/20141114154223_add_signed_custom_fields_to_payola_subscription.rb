class AddSignedCustomFieldsToPayolaSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :payola_subscriptions, :signed_custom_fields, :text
  end
end
