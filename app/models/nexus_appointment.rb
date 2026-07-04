class NexusAppointment < ApplicationRecord
  belongs_to :account
  belongs_to :nexus_service
  belongs_to :nexus_time_slot
  belongs_to :contact, optional: true

  enum status: { pending: 0, confirmed: 1, cancelled: 2, completed: 3, no_show: 4 }

  validates :nexus_time_slot, presence: true
  validate :slot_has_availability, on: :create

  after_create :increment_slot_bookings
  after_update :handle_cancellation, if: :saved_change_to_status?

  scope :recent, -> { order(created_at: :desc) }
  scope :upcoming, -> { joins(:nexus_time_slot).where('nexus_time_slots.start_time > ?', Time.current).order('nexus_time_slots.start_time') }

  private

  def slot_has_availability
    errors.add(:nexus_time_slot, 'has no availability') unless nexus_time_slot&.available?
  end

  def increment_slot_bookings
    nexus_time_slot.increment!(:current_bookings)
  end

  def handle_cancellation
    nexus_time_slot.decrement!(:current_bookings) if cancelled? && current_bookings_changed_to_cancelled?
  end

  def current_bookings_changed_to_cancelled?
    saved_change_to_status? && status == 'cancelled' && status_before_last_save != 'cancelled'
  end
end
