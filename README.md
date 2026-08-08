# Blotter

Personal investing portfolio tracker built on Rails 8. Holdings, allocation, and performance are derived from an immutable ledger of recorded events rather than stored as mutable state.

## Design

The governing constraint is that **the ledger is the only source of truth.** Blotter records discrete money events, a purchase, a fee, a dividend, and computes everything else on read.

The app therefore never stores "3 shares of VTI". It stores the line items that sum to three shares. Holdings, cost basis, allocation, and performance are all queries against that ledger.

The tradeoff is read cost against correctness. Summing a ledger on every request costs more than reading a cached total, but a cached total drifts, and drift in a financial record is both silent and difficult to reconstruct after the fact. At personal portfolio scale, thousands of rows rather than millions, the read cost is negligible, so correctness wins. Should the dashboard become slow, the remedy is a materialized holdings table, which is purely additive and leaves the ledger untouched.

A second constraint: **the app models the past only.** No projections, planned purchases, or target allocations. This is a deliberate scope boundary, and it is the reason there is no rules engine or scheduling model anywhere in the schema.

## Stack

Ruby 3.4.2, Rails 8.1, PostgreSQL 13.

Devise for authentication, Sidekiq with sidekiq-cron for scheduled work, Chartkick with groupdate for visualization, Blueprinter for JSON serialization, RSpec with FactoryBot and shoulda-matchers for tests.

## Data model

Nine tables. `entry_line_items` is the ledger; everything else either describes it or is derived from it.

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

Invariants worth knowing before touching the schema:

- `entry_line_items.amount` is signed, non null, and authoritative. It is deliberately not derived from `quantity * price_per_unit`, because fees, deposits, and transfers do not have that shape.
- `asset_prices` is append only. Current price is a query ordered by `as_of`, never a stored column.
- Categories attach to line items, not to entries. A single entry routinely mixes a buy and a fee, and each needs its own label.
- Snapshots are unique on `(portfolio_id, currency, captured_on)`.

## Design decisions

**Prices are a time series rather than a column.** A price is a fact about a date, not about an instrument. A single mutable `current_price` would be simpler to write and would destroy the history that every time series chart depends on, with no way to distinguish a stale value from a current one.

**Currency is never converted.** Assets carry their own currency and a portfolio holding both EUR and USD positions reports two totals rather than merging them behind an implied exchange rate. Snapshots follow the same rule. When FX support arrives it becomes a display layer over rows that are already individually correct, requiring no migration.

**Valuation happens on a schedule, not on write.** A nightly job records what each portfolio was worth, carrying forward the most recent known price for each asset. Manual price entry is too sparse to support live valuation history, and this keeps the expensive work off the request path. Assets with no price at all are counted in `unpriced_assets_count` so the interface can report an incomplete total instead of a wrong one.

## Getting started

Requires Ruby 3.4.2 and a running PostgreSQL instance.

```
bundle install
bin/rails db:setup
bin/rails server
```

```
bundle exec rspec
```

On WSL2, Postgres does not start automatically:

```
sudo service postgresql start
```

## Status

Schema complete and migrated. Models are generated but not yet implemented: no associations, enums, or validations.

Not yet started: controllers, views, CSV import and export, the JSON summary endpoint, charts, and the snapshot job.

## Roadmap

Allocation calculator, splitting a given sum across target percentages against current holdings. Assisted data entry, turning a line of natural language into a populated form, with the ledger write always gated behind explicit confirmation. FX conversion. Automated price feeds.
