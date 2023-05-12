# frozen_string_literal: true

class AddDeprecationReasonToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :deprecation_reason, :text
  end
end
