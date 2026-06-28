class Evolution::ApiClient
  class ConfigurationError < StandardError; end

  def self.base_url
    ENV.fetch('EVOLUTION_API_URL', '').to_s.chomp('/')
  end

  def self.api_key
    ENV.fetch('EVOLUTION_API_KEY', '').to_s
  end

  def self.configured?
    base_url.present? && api_key.present?
  end

  # Cria uma nova instância na Evolution API já vinculada a uma conta/inbox do Chatwoot.
  # Quando chatwoot_auto_create é true, a própria Evolution cria o inbox no Chatwoot
  # usando o token de acesso informado (ver app/models/concerns/access_tokenable.rb).
  def self.create_instance(instance_name:, chatwoot_account_id:, chatwoot_token:, chatwoot_url:)
    raise ConfigurationError, 'EVOLUTION_API_URL/EVOLUTION_API_KEY not configured' unless configured?

    payload = {
      instanceName: instance_name,
      integration: 'WHATSAPP-BAILEYS',
      qrcode: true,
      rejectCall: false,
      groupsIgnore: true,
      chatwootAccountId: chatwoot_account_id,
      chatwootToken: chatwoot_token,
      chatwootUrl: chatwoot_url,
      chatwootSignMsg: true,
      chatwootReopenConversation: true,
      chatwootConversationPending: false,
      chatwootImportContacts: true,
      chatwootNameInbox: 'WhatsApp',
      chatwootMergeBrazilContacts: true,
      chatwootAutoCreate: true
    }

    request(:post, '/instance/create', payload)
  end

  # Retorna { 'base64' => 'data:image/png;base64,...', 'pairingCode' => '...', 'count' => 1 }
  # Quando já está conectado, a Evolution costuma retornar sem a chave base64.
  def self.connect(instance_name)
    request(:get, "/instance/connect/#{instance_name}")
  end

  # Retorna { 'instance' => { 'instanceName' => '...', 'state' => 'open' | 'close' | 'connecting' } }
  def self.connection_state(instance_name)
    request(:get, "/instance/connectionState/#{instance_name}")
  end

  def self.logout(instance_name)
    request(:delete, "/instance/logout/#{instance_name}")
  end

  def self.delete_instance(instance_name)
    request(:delete, "/instance/delete/#{instance_name}")
  end

  def self.request(method, path, payload = nil)
    url = "#{base_url}#{path}"
    headers = { 'apikey' => api_key, content_type: :json, accept: :json }

    response = if %i[post put patch].include?(method)
                 RestClient::Request.execute(method: method, url: url, payload: payload.to_json, headers: headers, timeout: 15)
               else
                 RestClient::Request.execute(method: method, url: url, headers: headers, timeout: 15)
               end

    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("[Evolution::ApiClient] #{method.upcase} #{path} failed: #{e.response&.code} #{e.response&.body}")
    { 'error' => true, 'status' => e.response&.code, 'message' => e.response&.body }
  rescue Errno::ECONNREFUSED, RestClient::Exceptions::Timeout, SocketError => e
    Rails.logger.error("[Evolution::ApiClient] #{method.upcase} #{path} unreachable: #{e.message}")
    { 'error' => true, 'message' => e.message }
  end
end
