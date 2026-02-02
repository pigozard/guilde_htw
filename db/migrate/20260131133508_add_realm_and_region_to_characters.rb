class AddRealmAndRegionToCharacters < ActiveRecord::Migration[7.1]
  def change
    add_column :characters, :realm, :string
    add_column :characters, :region, :string, default: 'eu'
  end
end
