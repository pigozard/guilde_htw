class AddBlizzardIdToIngredients < ActiveRecord::Migration[7.1]
  def change
    add_column :ingredients, :blizzard_id, :integer
  end
end
