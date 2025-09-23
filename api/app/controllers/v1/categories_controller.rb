class V1::CategoriesController < ApplicationController
  before_action :set_user
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    categories = @user.categories.order(:name)
    render json: categories.as_json(only: [:id, :name, :color, :created_at, :updated_at])
  end

  def show
    render json: @category.as_json(
      only: [:id, :name, :color, :created_at, :updated_at],
      include: {
        transactions: {
          only: [:id, :date, :description, :amount],
          methods: [:formatted_amount]
        }
      }
    )
  end

  def create
    category = @user.categories.build(category_params)

    if category.save
      render json: category.as_json(only: [:id, :name, :color, :created_at, :updated_at]), status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: @category.as_json(only: [:id, :name, :color, :created_at, :updated_at])
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    transaction_count = @category.transactions.count
    @category.destroy!
    render json: {
      message: "Category deleted successfully",
      transactions_affected: transaction_count
    }
  end

  private

  def set_user
    @user = User.first || User.create!(email: "demo@example.com")
  end

  def set_category
    @category = @user.categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end
end