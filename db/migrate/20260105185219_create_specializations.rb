class CreateSpecializations < ActiveRecord::Migration[7.1]
  def change
    create_table :specializations do |t|
      t.string :name
      t.string :role
      t.references :wow_class, null: false, foreign_key: true
      t.string :icon

      t.timestamps
    end
  end
end
