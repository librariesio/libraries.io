# frozen_string_literal: true
class ChangeRepositoryUuidToString < ActiveRecord::Migration[5.0]
  def change
    change_column :repositories, :uuid, :string
  end
end
