class Api::V1::Accounts::Nexus::ProductsController < Api::V1::Accounts::Nexus::BaseController
  before_action :require_sales_module!
  before_action :check_admin_authorization?, only: [:create, :update, :destroy]
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = Current.account.nexus_products.ordered
    render json: @products.as_json(include: :nexus_product_variants)
  end

  def show
    render json: @product.as_json(include: :nexus_product_variants)
  end

  def create
    @product = Current.account.nexus_products.new(product_params)
    @product.save!
    render json: @product, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    @product.update!(product_params)
    render json: @product
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @product.destroy!
    head :ok
  rescue ActiveRecord::DeleteRestrictionError
    render json: { error: 'Produto possui pedidos vinculados e não pode ser excluído. Archive-o.' }, status: :unprocessable_entity
  end

  private

  def set_product
    @product = Current.account.nexus_products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :sku, :price, :status, :image_url, :stock_quantity)
  end
end
