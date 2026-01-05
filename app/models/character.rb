class Character < ApplicationRecord
  belongs_to :user
  belongs_to :wow_class
  belongs_to :specialization

  validates :pseudo, presence: true
end
