# frozen_string_literal: true

class AddHostTypeToIssues < ActiveRecord::Migration[5.0]
  def change
    add_column :issues, :host_type, :string
  end
end
