class ChangeKeywordsToText < ActiveRecord::Migration
  def change
    change_column :projects, :keywords, :text
  end
end
