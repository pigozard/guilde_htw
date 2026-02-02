class AddDisplayOrderToAchievements < ActiveRecord::Migration[7.1]
  def change
    add_column :achievements, :display_order, :integer, default: 0
    add_index :achievements, :display_order
  end
end
