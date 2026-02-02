class Expansion < ApplicationRecord
  has_many :achievements, dependent: :destroy

  validates :name, :code, :slug, presence: true
  validates :code, uniqueness: true

  scope :ordered, -> { order(:order_index) }
end
