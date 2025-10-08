class AnomalyDetector
  def initialize(user)
    @user = user
  end

  def scan!(scope: nil)
    rel = scope || @user.transactions

    flag_missing_metadata(rel)
    flag_duplicates(rel)
    flag_unusual_amounts(@user) # checks across user’s history
  end

  private

  # 3.a Missing metadata
  def flag_missing_metadata(rel)
    rel.where("COALESCE(TRIM(description), '') = ''").find_each do |t|
      ensure_flag(t, "missing_metadata", detail: "blank description")
    end
  end

  # 3.b Potential duplicates (same user/date/amount/normalized description)
  def flag_duplicates(rel)
    # group in Ruby for clarity; for scale you could do a SQL CTE with count>1
    rel.find_each do |t|
      dnorm = normalize_desc(t.description)
      dup = @user.transactions
                 .where(date: t.date, amount: t.amount)
                 .where("LOWER(REGEXP_REPLACE(description, '\\s+', ' ', 'g')) = ?", dnorm)
                 .where.not(id: t.id)
                 .exists?
      ensure_flag(t, "duplicate", detail: "same date/amount/description") if dup
    end
  end

  # 3.c Unusual amounts (simple robust z-score using median/MAD, fallback to stddev)
  def flag_unusual_amounts(user)
    amounts = user.transactions.where("amount IS NOT NULL").pluck(:amount).map(&:to_d)
    return if amounts.size < 10

    median = percentile(amounts, 0.5)
    mad = median_absolute_deviation(amounts, median)
    threshold = mad.positive? ? 3.5 : nil

    user.transactions.find_each do |t|
      next unless t.amount
      outlier =
        if threshold
          # robust z
          ((t.amount - median).abs / mad) > threshold
        else
          # fallback: > mean + 3*std
          mean, std = mean_std(amounts)
          t.amount > (mean + 3 * std)
        end
      ensure_flag(t, "unusual_amount", detail: "outlier vs history") if outlier
    end
  end

  def ensure_flag(txn, type, detail:)
    anomaly = txn.anomalies.where(flag_type: type, resolved: false).first
    return if anomaly # already flagged and unresolved
    txn.anomalies.create!(flag_type: type, details: { message: detail }, resolved: false)
  end

  def normalize_desc(s)
    s.to_s.downcase.strip.gsub(/\s+/, " ")
  end

  # stats helpers (in-memory; for 1M+ you’ll want SQL window functions / percentiles)
  def percentile(arr, p)
    sorted = arr.sort
    idx = (p * (sorted.length - 1)).round
    sorted[idx]
  end

  def median_absolute_deviation(arr, med)
    devs = arr.map { |x| (x - med).abs }
    m = percentile(devs, 0.5)
    # avoid divide-by-zero in robust z scaling
    m.zero? ? BigDecimal("0") : (m / 0.6745) # consistency with std normal
  end

  def mean_std(arr)
    mean = arr.sum(0.to_d) / arr.size
    var = arr.map { |x| (x - mean) ** 2 }.sum(0.to_d) / arr.size
    [mean, BigDecimal(var).sqrt(10)]
  end
end