class CreateCharacterAchievements < ActiveRecord::Migration[7.1]
  def change
    create_table :character_achievements do |t|
      t.references :character, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.boolean :completed, default: false
      t.datetime :completed_at

      t.timestamps
    end
    add_index :character_achievements, [:character_id, :achievement_id], unique: true, name: 'index_char_achievements_on_char_and_achievement'
  end
end
