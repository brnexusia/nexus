class NexusTimeSlot < ApplicationRecord
  belongs_to :account
  belongs_to :nexus_service
  has_many :nexus_appointments, dependent: :restrict_with_error

  validates :start_time, :end_time, presence: true
  validates :max_bookings, numericality: { greater_than: 0 }
  validate :end_after_start

  scope :available, -> { where('current_bookings < max_bookings').where('start_time > ?', Time.current) }
  scope :upcoming, -> { where('start_time > ?', Time.current).order(:start_time) }
  scope :for_range, ->(from, to) { where(start_time: from..to) }

  def available?
    current_bookings < max_bookings && start_time > Time.current
  end

  def slots_remaining
    max_bookings - current_bookings
  end

  private

  def end_after_start
    return unless start_time && end_time
    errors.add(:end_time, 'must be after start time') if end_time <= start_time
  end
end
