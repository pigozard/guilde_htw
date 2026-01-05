class WowClass < ApplicationRecord
  has_many :specializations, dependent: :destroy
  has_many :characters, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
