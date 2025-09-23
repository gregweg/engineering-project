class RuleEngine
  def initialize(user)
    @user  = user
    @rules = user.rules.enabled.order(priority: :asc)
  end

  # Apply rules to all (or a scope you pass in)
  def apply!(scope: nil)
    rel = scope || @user.transactions
    @rules.find_each do |rule|
      case rule.field
      when "description"
        target = case rule.operator
                 when "contains"
                   rel.where("LOWER(description) LIKE ?", "%#{sanitize(rule.value)}%")
                 when "equals"
                   rel.where("LOWER(description) = ?", sanitize(rule.value))
                 else rel.none
                 end
        perform_action(target, rule)
      when "amount"
        num = to_decimal(rule.value)
        target = case rule.operator
                 when "greater_than" then num ? rel.where("amount > ?", num) : rel.none
                 when "less_than"    then num ? rel.where("amount < ?", num) : rel.none
                 when "equals"       then num ? rel.where(amount: num)      : rel.none
                 else rel.none
                 end
        perform_action(target, rule)
      end
    end
  end

  private

  def sanitize(s) = ActiveRecord::Base.sanitize_sql_like(s.to_s.downcase)
  def to_decimal(v)
    str = v.to_s.strip.gsub(/[^\d\.\-]/, "")
    return nil unless str.match?(/\A-?\d+(\.\d+)?\z/)
    BigDecimal(str)
  end

  def perform_action(target, rule)
    case rule.action_type
    when "set_category"
      cat = @user.categories.where("LOWER(name)=?", rule.action_value.to_s.downcase)
                            .first_or_create!(name: rule.action_value.to_s)
      # don't override user-edited ones
      target.where(category_id: nil).update_all(category_id: cat.id)
    when "flag"
      target.update_all(needs_review: true)
    end
  end
end