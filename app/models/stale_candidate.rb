class StaleCandidate < ApplicationRecord
  enum coin: [:btc, :bch, :bsv, :tbtc]
end