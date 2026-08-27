# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Every entry line item needs an asset, even pure-cash actions like a fee or
# a deposit. These give a brand new account something to point at without
# having to create a cash asset by hand before the first entry.
[
  { symbol: "EUR-CASH", name: "Euro cash", currency: "EUR" },
  { symbol: "USD-CASH", name: "US dollar cash", currency: "USD" }
].each do |attrs|
  Asset.find_or_create_by!(symbol: attrs[:symbol]) do |asset|
    asset.name = attrs[:name]
    asset.currency = attrs[:currency]
    asset.asset_type = :cash
  end
end
