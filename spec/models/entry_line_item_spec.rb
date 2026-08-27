require 'rails_helper'

RSpec.describe EntryLineItem do
  describe "associations" do
    it { is_expected.to belong_to(:entry) }
    it { is_expected.to belong_to(:asset) }
    it { is_expected.to have_many(:categories).through(:category_entry_line_items) }
  end

  describe "the action enum" do
    it "matches the entry_action Postgres enum type" do
      expect(described_class.actions.keys).to eq(
        %w[buy sell dividend interest deposit withdrawal fee transfer_in transfer_out]
      )
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount) }

    it "requires a price per unit on a buy" do
      expect(build(:entry_line_item, action: :buy, price_per_unit: nil)).not_to be_valid
    end

    it "requires a nonzero quantity on a buy" do
      expect(build(:entry_line_item, action: :buy, quantity: 0)).not_to be_valid
    end

    # Cash-only actions have neither units nor a per-unit price, and requiring
    # them would make the entry form lie about what a fee is.
    it "allows a fee with no quantity and no price" do
      expect(build(:entry_line_item, :fee)).to be_valid
    end

    it "allows a deposit with no quantity and no price" do
      expect(build(:entry_line_item, :deposit)).to be_valid
    end

    it "rejects a negative price per unit" do
      expect(build(:entry_line_item, price_per_unit: -1)).not_to be_valid
    end

    it "rejects a negative quantity on a buy" do
      expect(build(:entry_line_item, action: :buy, quantity: -3)).not_to be_valid
    end

    it "rejects a negative quantity on a transfer" do
      expect(build(:entry_line_item, :transfer_in, quantity: -5)).not_to be_valid
    end

    it "rejects a buy whose amount does not match quantity times price" do
      expect(build(:entry_line_item, action: :buy, quantity: 3, price_per_unit: 250, amount: -700))
        .not_to be_valid
    end

    it "accepts a buy whose amount matches quantity times price" do
      expect(build(:entry_line_item, action: :buy, quantity: 3, price_per_unit: 250, amount: -750))
        .to be_valid
    end

    it "rejects a sell whose amount does not match quantity times price" do
      expect(build(:entry_line_item, :sell, quantity: 2, price_per_unit: 260, amount: 500))
        .not_to be_valid
    end

    it "does not require amount to match price on a transfer" do
      expect(build(:entry_line_item, :transfer_in, amount: 999)).to be_valid
    end
  end

  describe "#signed_quantity" do
    it "is positive for a buy" do
      expect(build(:entry_line_item, action: :buy, quantity: 3).signed_quantity).to eq(3)
    end

    it "is negative for a sell" do
      expect(build(:entry_line_item, :sell, quantity: 2).signed_quantity).to eq(-2)
    end

    it "is zero for cash-only actions" do
      expect(build(:entry_line_item, :fee).signed_quantity).to eq(0)
      expect(build(:entry_line_item, :dividend).signed_quantity).to eq(0)
    end

    it "is positive for a transfer in" do
      expect(build(:entry_line_item, :transfer_in, quantity: 5).signed_quantity).to eq(5)
    end

    it "is negative for a transfer out" do
      expect(build(:entry_line_item, :transfer_out, quantity: 5).signed_quantity).to eq(-5)
    end
  end

  describe "#display_description" do
    it "prefers the line item's own note" do
      line_item = build(:entry_line_item, notes: "Reinvested dividend", entry: build(:entry, description: "Monthly buy"))

      expect(line_item.display_description).to eq("Reinvested dividend")
    end

    it "falls back to the entry's description when there is no note" do
      line_item = build(:entry_line_item, notes: nil, entry: build(:entry, description: "Monthly buy"))

      expect(line_item.display_description).to eq("Monthly buy")
    end

    it "falls back to the action and ticker when neither was filled in" do
      asset = build(:asset, symbol: "AAPL")
      line_item = build(:entry_line_item, action: :buy, notes: nil, asset:, entry: build(:entry, description: nil))

      expect(line_item.display_description).to eq("Buy AAPL")
    end
  end

  describe "filtering scopes" do
    it ".for_user finds only line items belonging to that user" do
      mine = create(:entry_line_item, entry: create(:entry))
      create(:entry_line_item, entry: create(:entry))
      user = mine.entry.portfolio.user

      expect(described_class.for_user(user)).to contain_exactly(mine)
    end

    it ".in_portfolio narrows to one portfolio" do
      user = create(:user)
      brokerage = create(:portfolio, user:)
      crypto = create(:portfolio, user:)
      brokerage_line_item = create(:entry_line_item, entry: create(:entry, portfolio: brokerage))
      create(:entry_line_item, entry: create(:entry, portfolio: crypto))

      expect(described_class.in_portfolio(brokerage.id)).to contain_exactly(brokerage_line_item)
    end

    it ".with_action narrows to one action" do
      buy = create(:entry_line_item, action: :buy)
      create(:entry_line_item, :sell)

      expect(described_class.with_action("buy")).to contain_exactly(buy)
    end

    it ".chronological orders most recent first" do
      older = create(:entry_line_item, entry: create(:entry, occurred_on: 2.days.ago))
      newer = create(:entry_line_item, entry: create(:entry, occurred_on: 1.day.ago))

      expect(described_class.chronological).to eq([ newer, older ])
    end
  end

  describe "delegation" do
    it "reads occurred_on from its entry" do
      entry = create(:entry, occurred_on: Date.new(2026, 3, 1))

      expect(create(:entry_line_item, entry:).occurred_on).to eq(Date.new(2026, 3, 1))
    end
  end
end
