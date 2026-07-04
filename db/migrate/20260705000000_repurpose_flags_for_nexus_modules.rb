class RepurposeFlagsForNexusModules < ActiveRecord::Migration[7.1]
  def up
    # message_reply_to (deprecated) foi renomeada para nexus_sales.
    # insert_article_in_reply (deprecated) foi renomeada para nexus_scheduling.
    # Desliga a flag em qualquer conta que ainda tivesse o valor antigo ligado,
    # para que a flag reaproveitada comece desligada por padrão (comportamento pretendido).
    Account.feature_nexus_sales.find_each(batch_size: 100) do |account|
      account.disable_features(:nexus_sales)
      account.save!(validate: false)
    end

    Account.feature_nexus_scheduling.find_each(batch_size: 100) do |account|
      account.disable_features(:nexus_scheduling)
      account.save!(validate: false)
    end

    # Remove as entradas antigas do ACCOUNT_LEVEL_FEATURE_DEFAULTS, se existirem
    # (o ConfigLoader só adiciona flags novas, nunca remove as renomeadas).
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| %w[message_reply_to insert_article_in_reply].include?(feature['name']) }
    config.save!
    GlobalConfig.clear_cache
  end
end
