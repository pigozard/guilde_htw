class CreateGuildStatistics < ActiveRecord::Migration[7.0]
  def change
    create_table :guild_statistics do |t|
      t.string :stat_type, null: false
      t.json :data

      t.timestamps  # Ceci ajoute déjà created_at et updated_at
    end

    add_index :guild_statistics, :stat_type, unique: true
  end
end
