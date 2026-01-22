class AddBlizzardIdToConsumables < ActiveRecord::Migration[7.1]
  def change
    add_column :consumables, :blizzard_id, :integer
  end
end
