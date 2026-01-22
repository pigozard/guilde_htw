class CreateConsumableSelections < ActiveRecord::Migration[7.1]
  def change
    create_table :consumable_selections do |t|
      t.references :user, null: false, foreign_key: true
      t.references :consumable, null: false, foreign_key: true
      t.integer :quantity
      t.date :week

      t.timestamps
    end
  end
end
