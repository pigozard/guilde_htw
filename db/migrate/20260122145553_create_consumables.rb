class CreateConsumables < ActiveRecord::Migration[7.1]
  def change
    create_table :consumables do |t|
      t.string :name
      t.string :category
      t.string :expansion
      t.string :icon_name

      t.timestamps
    end
  end
end
