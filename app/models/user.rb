class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable

  has_many :characters, dependent: :destroy
  has_many :events, dependent: :destroy

  validates :pseudo, presence: true, uniqueness: true

  def display_name
  pseudo.presence || email.split("@").first
  end

end
