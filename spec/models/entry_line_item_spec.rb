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

  describe "delegation" do
    it "reads occurred_on from its entry" do
      entry = create(:entry, occurred_on: Date.new(2026, 3, 1))

      expect(create(:entry_line_item, entry:).occurred_on).to eq(Date.new(2026, 3, 1))
    end
  end
end
