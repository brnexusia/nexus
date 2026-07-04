class NexusOrder < ApplicationRecord
  belongs_to :account
  belongs_to :contact, optional: true
  has_many :nexus_order_items, dependent: :destroy

  enum status: { pending: 0, confirmed: 1, cancelled: 2, completed: 3 }

  validates :total, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }

  def recalculate_total!
    update!(total: nexus_order_items.sum { |i| i.unit_price * i.quantity })
  end
end
