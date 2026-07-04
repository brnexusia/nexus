class CreateNexusSchedulingTables < ActiveRecord::Migration[7.1]
  def change
    create_table :nexus_services do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.integer :duration_minutes, null: false, default: 60
      t.decimal :price, precision: 10, scale: 2, default: 0, null: false
      t.integer :status, default: 0, null: false # 0=active 1=archived
      t.string :color, default: '#A9602D'

      t.timestamps
    end
    add_index :nexus_services, [:account_id, :status]

    create_table :nexus_time_slots do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :nexus_service, null: false, foreign_key: true, index: true
      t.bigint :agent_id
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :max_bookings, default: 1, null: false
      t.integer :current_bookings, default: 0, null: false

      t.timestamps
    end
    add_index :nexus_time_slots, [:account_id, :start_time]
    add_index :nexus_time_slots, [:nexus_service_id, :start_time]

    create_table :nexus_appointments do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :nexus_service, null: false, foreign_key: true, index: true
      t.references :nexus_time_slot, null: false, foreign_key: true, index: true
      t.references :contact, null: true, foreign_key: true, index: true
      t.bigint :conversation_id
      t.bigint :agent_id
      t.integer :status, default: 0, null: false # 0=pending 1=confirmed 2=cancelled 3=completed 4=no_show
      t.text :notes

      t.timestamps
    end
    add_index :nexus_appointments, [:account_id, :status]
  end
end
