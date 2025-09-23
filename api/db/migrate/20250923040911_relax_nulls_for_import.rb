class RelaxNullsForImport < ActiveRecord::Migration[8.0]
  def change
    # Allow missing/invalid values to be stored, importer will flag them.
    change_column_null :transactions, :amount, true
    change_column_null :transactions, :date,   true  # optional but recommended
    # If you also made :description NOT NULL earlier, relax it as well:
    # change_column_null :transactions, :description, true
  end
end
