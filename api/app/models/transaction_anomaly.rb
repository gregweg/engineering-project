class TransactionAnomaly < ApplicationRecord
  belongs_to :txn, class_name: "Transaction"
  FLAG_TYPES = %w[
    unusual_amount
    duplicate
    missing_metadata
    invalid_amount
    invalid_date
    manual
  ].freeze

  validates :flag_type, inclusion: { in: FLAG_TYPES }

  after_commit :sync_txn_review_flag

  private

  def sync_txn_review_flag
    return unless txn
    # fast toggle on the parent
    has_open = txn.anomalies.where(resolved: false).exists?
    txn.update_columns(needs_review: has_open) # skip validations/callbacks
  end
end
