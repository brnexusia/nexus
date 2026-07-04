class Api::V1::Accounts::Nexus::BaseController < Api::V1::Accounts::BaseController
  private

  def require_sales_module!
    return if Current.account.feature_enabled?('nexus_sales')

    render json: { error: 'O módulo de Vendas não está ativado nesta conta.' }, status: :forbidden
  end

  def require_scheduling_module!
    return if Current.account.feature_enabled?('nexus_scheduling')

    render json: { error: 'O módulo de Agendamento não está ativado nesta conta.' }, status: :forbidden
  end
end
