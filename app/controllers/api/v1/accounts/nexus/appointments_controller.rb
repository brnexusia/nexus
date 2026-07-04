class Api::V1::Accounts::Nexus::AppointmentsController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_scheduling_module!
  before_action :set_appointment, only: [:show, :update, :destroy]

  def index
    from = params[:from] ? Time.zone.parse(params[:from]) : Time.current.beginning_of_month
    to   = params[:to]   ? Time.zone.parse(params[:to])   : Time.current.end_of_month

    @appointments = Current.account.nexus_appointments
                            .joins(:nexus_time_slot)
                            .where(nexus_time_slots: { start_time: from..to })
                            .includes(:nexus_service, :nexus_time_slot, :contact)
                            .order('nexus_time_slots.start_time')

    render json: @appointments.as_json(
      include: {
        nexus_service: { only: [:id, :name, :color] },
        nexus_time_slot: { only: [:id, :start_time, :end_time] },
        contact: { only: [:id, :name, :phone_number] }
      }
    )
  end

  def show
    render json: @appointment.as_json(include: [:nexus_service, :nexus_time_slot, :contact])
  end

  def create
    slot = Current.account.nexus_time_slots.find(params[:appointment][:nexus_time_slot_id])
    @appointment = Current.account.nexus_appointments.new(appointment_params)
    @appointment.nexus_service = slot.nexus_service
    @appointment.save!
    render json: @appointment, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @appointment.update!(update_params)
    render json: @appointment
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @appointment.update!(status: :cancelled)
    head :ok
  end

  private

  def set_appointment
    @appointment = Current.account.nexus_appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:nexus_time_slot_id, :contact_id, :conversation_id, :agent_id, :notes)
  end

  def update_params
    params.require(:appointment).permit(:status, :notes)
  end
end
