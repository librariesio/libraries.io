class AddKeywordsArrayToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :keywords_array, :string, array: true, default: []
  end
end
