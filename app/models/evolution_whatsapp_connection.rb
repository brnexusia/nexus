# == Schema Information
#
# Table name: evolution_whatsapp_connections
#
#  id             :bigint           not null, primary key
#  instance_name  :string           not null
#  instance_token :string
#  last_error     :text
#  phone_number   :string
#  status         :string           default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  inbox_id       :bigint
#
class EvolutionWhatsappConnection < ApplicationRecord
  belongs_to :account

  validates :instance_name, presence: true, uniqueness: true

  def connected?
    status == 'connected'
  end
end
