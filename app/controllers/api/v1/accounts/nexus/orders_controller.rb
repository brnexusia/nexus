class Api::V1::Accounts::Nexus::OrdersController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_sales_module!
  before_action :check_admin_authorization?, only: [:destroy]
  before_action :set_order, only: [:show, :update, :destroy]

  def index
    @orders = Current.account.nexus_orders.recent
                      .includes(:contact, :nexus_order_items)
    render json: @orders.as_json(include: { nexus_order_items: {}, contact: { only: [:id, :name, :phone_number] } })
  end

  def show
    render json: @order.as_json(include: { nexus_order_items: {}, contact: { only: [:id, :name, :phone_number] } })
  end

  def create
    ActiveRecord::Base.transaction do
      @order = Current.account.nexus_orders.new(order_params)
      @order.save!
      build_order_items!
      @order.recalculate_total!
    end
    render json: @order, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @order.update!(update_order_params)
    render json: @order
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @order.destroy!
    head :ok
  end

  private

  def set_order
    @order = Current.account.nexus_orders.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:contact_id, :conversation_id, :notes)
  end

  def update_order_params
    params.require(:order).permit(:status, :notes)
  end

  def build_order_items!
    return unless params[:items].present?

    params[:items].each do |item|
      product = Current.account.nexus_products.find(item[:product_id])
      @order.nexus_order_items.create!(
        nexus_product: product,
        nexus_product_variant_id: item[:variant_id],
        quantity: item[:quantity].to_i,
        unit_price: item[:unit_price] || product.price,
        product_name_snapshot: product.name
      )
    end
  end
end
