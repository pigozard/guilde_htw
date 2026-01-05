class Specialization < ApplicationRecord
  belongs_to :wow_class
  has_many :characters, dependent: :destroy

  validates :name, presence: true
  validates :role, presence: true
end
