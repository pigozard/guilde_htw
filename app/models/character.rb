class Character < ApplicationRecord
  belongs_to :user
  belongs_to :wow_class, optional: true
  belongs_to :specialization, optional: true

  validates :pseudo, presence: true
end
