class AddTagsToAchievements < ActiveRecord::Migration[7.1]
  def change
    add_column :achievements, :tags, :string
    add_column :achievements, :is_feat_of_strength, :boolean, default: false
    add_index :achievements, :tags
    add_index :achievements, :is_feat_of_strength
  end
end
