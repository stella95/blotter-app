require 'rails_helper'

RSpec.describe User do
  it { is_expected.to have_many(:portfolios).dependent(:destroy) }
  it { is_expected.to have_many(:categories).dependent(:destroy) }

  describe "time_zone" do
    it "defaults to UTC" do
      expect(described_class.new.time_zone).to eq("UTC")
    end

    it "rejects a zone Rails does not recognize" do
      expect(build(:user, time_zone: "Middle Earth")).not_to be_valid
    end
  end

  describe "#today" do
    # Every "today" in the app resolves through here, so a user in Europe is
    # not told their evening entry is dated tomorrow.
    it "resolves against the user's own zone" do
      user = build(:user, time_zone: "Auckland")

      travel_to Time.utc(2026, 8, 8, 23, 0) do
        expect(user.today).to eq(Date.new(2026, 8, 9))
      end
    end

    it "matches the server date for a UTC user" do
      user = build(:user, time_zone: "UTC")

      travel_to Time.utc(2026, 8, 8, 23, 0) do
        expect(user.today).to eq(Date.new(2026, 8, 8))
      end
    end
  end
end
