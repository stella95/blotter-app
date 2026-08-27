class RemoveCurrencyFromPortfolios < ActiveRecord::Migration[8.1]
  # A portfolio can hold assets in more than one currency (a EUR-labelled
  # brokerage account holding a USD stock is the normal case, not an edge
  # case). Currency belongs on the asset, never the portfolio, per the
  # governing decision in CLAUDE.md; this column predates that decision
  # and nothing in the app actually depended on it being single-valued.
  def change
    remove_column :portfolios, :currency, :string, default: "EUR", null: false
  end
end
