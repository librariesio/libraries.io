class AddIndexToKeywordsArray < ActiveRecord::Migration
  def change
    add_index :projects, :keywords_array, using: 'gin'
  end
end
