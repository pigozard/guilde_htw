class AddCategoryToAchievements < ActiveRecord::Migration[7.1]
  def change
    add_column :achievements, :category, :string
    add_column :achievements, :subcategory, :string
    add_index :achievements, :category
  end
end
