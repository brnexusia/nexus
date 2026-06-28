class Api::V1::Accounts::EvolutionConnectionsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :set_connection, only: [:show, :destroy]

  def show
    return render json: { status: 'not_connected' } if @connection.blank?

    refresh_qr_if_needed
    render json: connection_payload
  end

  def create
    return render json: { error: 'Evolution API is not configured on this server (EVOLUTION_API_URL / EVOLUTION_API_KEY).' }, status: :unprocessable_entity unless Evolution::ApiClient.configured?
    return render json: { error: 'FRONTEND_URL is not configured on this server.' }, status: :unprocessable_entity if ENV['FRONTEND_URL'].blank?

    existing = Current.account.evolution_whatsapp_connection
    return render json: connection_payload_for(existing) if existing.present?

    instance_name = "nexus_acc#{Current.account.id}_#{SecureRandom.hex(4)}"
    result = Evolution::ApiClient.create_instance(
      instance_name: instance_name,
      chatwoot_account_id: Current.account.id,
      chatwoot_token: Current.user.access_token.token,
      chatwoot_url: ENV.fetch('FRONTEND_URL')
    )

    if result['error']
      render json: { error: result['message'] || 'Failed to create the Evolution instance' }, status: :unprocessable_entity
      return
    end

    connection = Current.account.create_evolution_whatsapp_connection!(
      instance_name: instance_name,
      instance_token: result['hash'],
      status: 'qr'
    )

    render json: connection_payload_for(connection, qr: result.dig('qrcode', 'base64'))
  end

  def destroy
    return head :ok if @connection.blank?

    Evolution::ApiClient.logout(@connection.instance_name)
    @connection.update!(status: 'disconnected')
    render json: connection_payload
  end

  private

  def set_connection
    @connection = Current.account.evolution_whatsapp_connection
  end

  def refresh_qr_if_needed
    return if @connection.connected?

    state = Evolution::ApiClient.connection_state(@connection.instance_name)
    current_state = state.dig('instance', 'state')

    if current_state == 'open'
      @connection.update!(status: 'connected', last_error: nil)
    else
      qr_response = Evolution::ApiClient.connect(@connection.instance_name)
      @qr_base64 = qr_response['base64']
      @connection.update!(status: 'qr') if @connection.status != 'qr'
    end
  end

  def connection_payload
    connection_payload_for(@connection, qr: @qr_base64)
  end

  def connection_payload_for(connection, qr: nil)
    {
      status: connection.status,
      instance_name: connection.instance_name,
      phone_number: connection.phone_number,
      qrcode: qr
    }
  end
end
