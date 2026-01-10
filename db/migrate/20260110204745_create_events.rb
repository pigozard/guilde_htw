class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.string :event_type, default: "raid"
      t.integer :max_participants
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    create_table :event_participations do |t|
      t.references :event, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.references :specialization, foreign_key: true
      t.string :status, default: "confirmed"

      t.timestamps
    end

    add_index :event_participations, [:event_id, :character_id], unique: true
  end
end
