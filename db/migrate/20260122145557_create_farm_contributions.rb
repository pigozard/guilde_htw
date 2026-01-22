class CreateFarmContributions < ActiveRecord::Migration[7.1]
  def change
    create_table :farm_contributions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.integer :quantity
      t.date :week

      t.timestamps
    end
  end
end
