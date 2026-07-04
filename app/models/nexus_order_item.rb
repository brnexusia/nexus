class NexusOrderItem < ApplicationRecord
  belongs_to :nexus_order
  belongs_to :nexus_product

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :snapshot_product_name

  def line_total
    unit_price * quantity
  end

  private

  def snapshot_product_name
    self.product_name_snapshot ||= nexus_product&.name
  end
end
