class CreateEvolutionWhatsappConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :evolution_whatsapp_connections do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.bigint :inbox_id
      t.string :instance_name, null: false
      t.string :instance_token
      t.string :status, default: 'pending', null: false # pending, qr, connected, disconnected, error
      t.string :phone_number
      t.text :last_error

      t.timestamps
    end

    add_index :evolution_whatsapp_connections, :instance_name, unique: true
  end
end
