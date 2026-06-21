class AddInRosterToCharacters < ActiveRecord::Migration[7.1]
  def change
    add_column :characters, :in_roster, :boolean, default: true, null: false
  end
end
