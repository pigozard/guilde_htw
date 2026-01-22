class Recipe < ApplicationRecord
  belongs_to :consumable
  belongs_to :ingredient

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :ingredient_id, uniqueness: { scope: :consumable_id, message: "déjà utilisé dans cette recette" }
end
