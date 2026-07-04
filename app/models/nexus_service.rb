class NexusService < ApplicationRecord
  belongs_to :account
  has_many :nexus_time_slots, dependent: :destroy
  has_many :nexus_appointments, dependent: :restrict_with_error

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true
  validates :duration_minutes, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:name) }
end
