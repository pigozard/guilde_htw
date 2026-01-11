class AddTemporaryToCharacters < ActiveRecord::Migration[7.1]
  def change
    add_column :characters, :temporary, :boolean, default: false
  end
end
