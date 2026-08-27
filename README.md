# Blotter

Every portfolio tracker I tried was either a spreadsheet with no
structure or a product with more opinions about my money than I have. I
wanted something smaller than that: enter what actually happened, see
what you hold, nothing else competing for attention on the screen.

Blotter is a personal investing portfolio tracker built on Rails 8.
Holdings, allocation, and performance are derived from a ledger of
recorded events on every read, never stored as a running balance that
could quietly drift out of sync. The same restraint carries into the
interface: one list you can actually read, no chart or dashboard you
didn't ask for.

## Stack

Ruby 3.4.2, Rails 8.1, PostgreSQL. Hotwire (Turbo + Stimulus), Devise for
auth, Sidekiq with sidekiq-cron for scheduled work, Blueprinter for JSON,
RSpec with FactoryBot and shoulda-matchers.

## Data model

Nine tables. `entry_line_items` is the ledger, everything else either
describes it or is derived from it.

| Table | Role |
|---|---|
| `users` | Devise accounts, with a time zone for period boundaries |
| `portfolios` | Account groupings such as Retirement or Brokerage |
| `assets` | Catalogue of instruments, one flat table with a type enum |
| `asset_prices` | Append only price history |
| `categories` | User defined labels |
| `category_entry_line_items` | Join table |
| `entries` | Ledger header: date, description, portfolio |
| `entry_line_items` | The ledger |
| `portfolio_snapshots` | Nightly valuation, one row per portfolio per currency |

## Design decisions

- **The ledger is the only source of truth.** Holdings and totals are
  `SUM`s over line items, never a cached column that could fall out of sync.
- **A portfolio has no currency of its own.** A EUR account holding a USD
  stock is normal, not an edge case, so totals group by currency instead
  of a made up exchange rate.
- **`action` and `asset_type` are native Postgres enums**, not Rails
  integer enums, so the database itself rejects a bad value.
- **Prices are a time series, not a column.** `asset_prices` is append
  only, the current price is a query ordered by `as_of`.
- **Fees are always their own line item**, never folded into a buy or
  sell, which is what makes `amount == quantity * price_per_unit` a real
  check instead of a coincidence.

## Status

Portfolios, Assets, Entries, Categories, and a live Dashboard are built
and tested, 177 specs passing, rubocop clean. A nightly snapshot job, a
value over time chart, and CSV export are next.

## Run it

```
bundle install
bin/rails db:setup
bin/rails server
```

```
bundle exec rspec
```
