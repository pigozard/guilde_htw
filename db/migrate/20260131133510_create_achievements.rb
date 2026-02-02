class CreateAchievements < ActiveRecord::Migration[7.1]
  def change
    create_table :achievements do |t|
      t.integer :blizzard_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :icon
      t.integer :points, default: 0
      t.references :expansion, null: false, foreign_key: true

      t.timestamps
    end
    add_index :achievements, :blizzard_id, unique: true
  end
end
