class RebrandInstallationToArles < ActiveRecord::Migration[7.0]
  BRAND_VALUES = {
    'INSTALLATION_NAME' => 'Arles',
    'BRAND_NAME' => 'Arles',
    'BRAND_URL' => 'https://arlesglobal.com.br',
    'WIDGET_BRAND_URL' => 'https://arlesglobal.com.br',
    'DISPLAY_MANIFEST' => false
  }.freeze

  PLACEHOLDER_LEGAL_URLS = {
    'TERMS_URL' => 'https://SEUSITE.com.br/termos-de-servico',
    'PRIVACY_URL' => 'https://SEUSITE.com.br/politica-de-privacidade'
  }.freeze

  def up
    BRAND_VALUES.each do |name, value|
      config = InstallationConfig.find_by(name: name)
      next unless config

      config.value = value
      config.save!
    end

    # Remove only the old placeholder legal URLs. Real URLs configured by the
    # installation administrator are intentionally preserved.
    PLACEHOLDER_LEGAL_URLS.each do |name, placeholder|
      config = InstallationConfig.find_by(name: name)
      next unless config&.value == placeholder

      config.value = nil
      config.save!
    end

    GlobalConfig.clear_cache
  end
end
