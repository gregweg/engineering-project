class Rule < ApplicationRecord
  belongs_to :user

  FIELDS    = %w[description amount].freeze
  OPERATORS = %w[contains equals greater_than less_than].freeze
  ACTIONS   = %w[set_category flag].freeze

  validates :field,       presence: true, inclusion: { in: FIELDS }
  validates :operator,    presence: true, inclusion: { in: OPERATORS }
  validates :action_type, presence: true, inclusion: { in: ACTIONS }
  validates :priority,    numericality: { only_integer: true }, allow_nil: true
  scope :enabled, -> { where(enabled: true) }
  default_scope { order(priority: :asc) }
end