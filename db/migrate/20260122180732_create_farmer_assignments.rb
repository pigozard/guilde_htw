class CreateFarmerAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :farmer_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.date :week

      t.timestamps
    end
  end
end
