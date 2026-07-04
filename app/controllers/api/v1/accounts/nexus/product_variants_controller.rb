class Api::V1::Accounts::Nexus::ProductVariantsController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_sales_module!
  before_action :check_admin_authorization?
  before_action :set_product
  before_action :set_variant, only: [:update, :destroy]

  def index
    render json: @product.nexus_product_variants
  end

  def create
    @variant = @product.nexus_product_variants.new(variant_params.merge(account: Current.account))
    @variant.save!
    render json: @variant, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @variant.update!(variant_params)
    render json: @variant
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @variant.destroy!
    head :ok
  end

  private

  def set_product
    @product = Current.account.nexus_products.find(params[:product_id])
  end

  def set_variant
    @variant = @product.nexus_product_variants.find(params[:id])
  end

  def variant_params
    params.require(:variant).permit(:name, :sku, :price, :stock_quantity)
  end
end
