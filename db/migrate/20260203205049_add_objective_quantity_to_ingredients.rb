class AddObjectiveQuantityToIngredients < ActiveRecord::Migration[7.0]
  def change
    add_column :ingredients, :objective_quantity, :integer, default: 500
  end
end
