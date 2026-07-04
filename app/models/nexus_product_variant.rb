class NexusProductVariant < ApplicationRecord
  belongs_to :account
  belongs_to :nexus_product

  validates :name, presence: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  def effective_price
    price || nexus_product.price
  end
end
