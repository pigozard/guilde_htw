class CreateExpansions < ActiveRecord::Migration[7.1]
  def change
    create_table :expansions do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :slug, null: false
      t.integer :order_index, default: 0

      t.timestamps
    end
    add_index :expansions, :code, unique: true
  end
end
