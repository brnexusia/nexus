class NexusProduct < ApplicationRecord
  belongs_to :account
  has_many :nexus_product_variants, dependent: :destroy
  has_many :nexus_order_items, dependent: :restrict_with_error

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { scope: :account_id }, allow_blank: true

  scope :ordered, -> { order(:name) }

  def available?
    active? && (stock_quantity > 0 || nexus_product_variants.any? { |v| v.stock_quantity > 0 })
  end
end
