class Api::V1::Accounts::Nexus::ServicesController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_scheduling_module!
  before_action :check_admin_authorization?, only: [:create, :update, :destroy]
  before_action :set_service, only: [:show, :update, :destroy]

  def index
    @services = Current.account.nexus_services.ordered
    render json: @services
  end

  def show
    render json: @service
  end

  def create
    @service = Current.account.nexus_services.new(service_params)
    @service.save!
    render json: @service, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @service.update!(service_params)
    render json: @service
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @service.destroy!
    head :ok
  rescue ActiveRecord::DeleteRestrictionError
    render json: { error: 'Serviço possui agendamentos e não pode ser excluído. Archive-o.' }, status: :unprocessable_entity
  end

  private

  def set_service
    @service = Current.account.nexus_services.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :description, :duration_minutes, :price, :status, :color)
  end
end
