class AllowNullInCharacters < ActiveRecord::Migration[7.0]
  def change
    change_column_null :characters, :wow_class_id, true
    change_column_null :characters, :specialization_id, true
  end
end
