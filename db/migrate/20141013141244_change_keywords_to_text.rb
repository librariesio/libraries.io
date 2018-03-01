class ChangeKeywordsToText < ActiveRecord::Migration[5.0]
  def change
    change_column :projects, :keywords, :text
  end
end
