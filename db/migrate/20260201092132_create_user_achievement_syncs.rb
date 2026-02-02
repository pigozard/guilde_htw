class CreateUserAchievementSyncs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_achievement_syncs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :character_name
      t.string :realm
      t.string :region, default: 'eu'
      t.text :synced_achievement_ids
      t.datetime :synced_at

      t.timestamps
    end

    add_index :user_achievement_syncs, [:user_id, :character_name, :realm], unique: true, name: 'index_user_achievement_syncs_on_user_and_character'
  end
end
