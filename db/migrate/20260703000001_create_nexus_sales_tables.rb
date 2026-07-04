class CreateNexusSalesTables < ActiveRecord::Migration[7.1]
  def change
    create_table :nexus_products do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.string :sku
      t.decimal :price, precision: 10, scale: 2, default: 0, null: false
      t.integer :status, default: 0, null: false # 0=active 1=archived
      t.string :image_url
      t.integer :stock_quantity, default: 0, null: false

      t.timestamps
    end
    add_index :nexus_products, [:account_id, :status]
    add_index :nexus_products, [:account_id, :sku], unique: true,
              where: 'sku IS NOT NULL', name: 'idx_nexus_products_account_sku'

    create_table :nexus_product_variants do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :nexus_product, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :sku
      t.decimal :price, precision: 10, scale: 2
      t.integer :stock_quantity, default: 0, null: false

      t.timestamps
    end

    create_table :nexus_orders do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :contact, null: true, foreign_key: true, index: true
      t.bigint :conversation_id
      t.integer :status, default: 0, null: false # 0=pending 1=confirmed 2=cancelled 3=completed
      t.decimal :total, precision: 10, scale: 2, default: 0, null: false
      t.text :notes

      t.timestamps
    end
    add_index :nexus_orders, [:account_id, :status]
    add_index :nexus_orders, [:account_id, :conversation_id]

    create_table :nexus_order_items do |t|
      t.references :nexus_order, null: false, foreign_key: true, index: true
      t.references :nexus_product, null: false, foreign_key: true, index: true
      t.bigint :nexus_product_variant_id
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.string :product_name_snapshot
      t.string :variant_name_snapshot

      t.timestamps
    end
  end
end
