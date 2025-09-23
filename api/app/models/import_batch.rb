class ImportBatch < ApplicationRecord
  belongs_to :user

  STATUSES = %w[queued processing done failed].freeze

  validates :status, inclusion: { in: STATUSES }
end