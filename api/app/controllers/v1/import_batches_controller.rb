class V1::ImportBatchesController < ApplicationController
  before_action :set_user

  def show
    batch = @user.import_batches.find(params[:id])
    render json: {
      id: batch.id,
      status: batch.status,
      total_rows: batch.total_rows,
      processed_rows: batch.processed_rows,
      error_messages: batch.error_messages
    }
  end

  private
  def set_user
    @user = User.first || User.create!(email: "demo@example.com")
  end
end