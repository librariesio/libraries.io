# frozen_string_literal: true

class AddStatusReasonToProjectAndRepository < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :status_reason, :string
    add_column :repositories, :status_reason, :string
  end
end
