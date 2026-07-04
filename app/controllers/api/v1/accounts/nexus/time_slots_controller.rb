class Api::V1::Accounts::Nexus::TimeSlotsController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_scheduling_module!
  before_action :check_admin_authorization?, only: [:create, :update, :destroy]
  before_action :set_service
  before_action :set_slot, only: [:update, :destroy]

  def index
    from = params[:from] ? Time.zone.parse(params[:from]) : Time.current.beginning_of_month
    to   = params[:to]   ? Time.zone.parse(params[:to])   : Time.current.end_of_month

    @slots = @service.nexus_time_slots.for_range(from, to).order(:start_time)
    render json: @slots.as_json(methods: [:available?, :slots_remaining])
  end

  def create
    @slot = @service.nexus_time_slots.new(slot_params.merge(account: Current.account))
    @slot.save!
    render json: @slot, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @slot.update!(slot_params)
    render json: @slot
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @slot.destroy!
    head :ok
  rescue ActiveRecord::DeleteRestrictionError
    render json: { error: 'Slot possui agendamentos confirmados.' }, status: :unprocessable_entity
  end

  private

  def set_service
    @service = Current.account.nexus_services.find(params[:service_id])
  end

  def set_slot
    @slot = @service.nexus_time_slots.find(params[:id])
  end

  def slot_params
    params.require(:time_slot).permit(:start_time, :end_time, :max_bookings, :agent_id)
  end
end
