class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :characters, dependent: :destroy
  has_many :event_participations, dependent: :destroy
  has_many :created_events, class_name: 'Event', dependent: :destroy  # ← NOUVELLE LIGNE
  has_many :events, through: :event_participations
  has_many :farm_contributions, dependent: :destroy
  has_many :consumable_selections, dependent: :destroy
  has_many :farmer_assignments, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true

  # Méthodes
  def display_name
    nickname.presence || email.split('@').first.capitalize
  end

  def main_character
    characters.find_by(main: true) || characters.first
  end
end
