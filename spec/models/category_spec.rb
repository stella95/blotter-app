require 'rails_helper'

RSpec.describe Category do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:entry_line_items).through(:category_entry_line_items) }

  describe "validations" do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive }

    # Categories are curated per user, so two people can both have "Fees"
    # without colliding.
    it "lets two users each define the same name" do
      create(:category, user: create(:user), name: "Speculative")

      expect(build(:category, user: create(:user), name: "Speculative")).to be_valid
    end

    it "accepts a blank colour" do
      expect(build(:category, color: nil)).to be_valid
    end

    it "rejects a colour that is not a six digit hex code" do
      expect(build(:category, color: "blue")).not_to be_valid
    end
  end
end
