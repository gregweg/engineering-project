class V1::RulesController < ApplicationController
  before_action :set_user
  before_action :set_rule, only: [:show, :update, :destroy]

  def index
    render json: @user.rules.order(:priority).as_json(
      only: [:id, :field, :operator, :value, :action_type, :action_value, :priority, :enabled, :created_at, :updated_at]
    )
  end

  def show
    render json: @rule.as_json(
      only: [:id, :field, :operator, :value, :action_type, :action_value, :priority, :enabled, :created_at, :updated_at]
    )
  end

  def create
    rule = @user.rules.create!(rule_params)
    RuleApplyJob.perform_later(@user.id)
    render json: rule, status: :created
  end

  def update
    if @rule.update(rule_params)
      RuleApplyJob.perform_later(@user.id)
      render json: @rule.as_json(
        only: [:id, :field, :operator, :value, :action_type, :action_value, :priority, :enabled, :created_at, :updated_at]
      )
    else
      render json: { errors: @rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy!
    RuleApplyJob.perform_later(@user.id)
    render json: { message: "Rule deleted successfully" }
  end

  private

  def set_user
    @user = User.first || User.create!(email: "demo@example.com")
  end

  def set_rule
    @rule = @user.rules.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Rule not found" }, status: :not_found
  end

  def rule_params
    params.require(:rule).permit(:field, :operator, :value, :action_type, :action_value, :priority, :enabled)
  end
end