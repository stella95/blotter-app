require 'rails_helper'

RSpec.describe User do
  it { is_expected.to have_many(:portfolios).dependent(:destroy) }
  it { is_expected.to have_many(:categories).dependent(:destroy) }

  describe "default categories" do
    it "seeds a starter set on creation so the picker is never empty" do
      user = create(:user)

      expect(user.categories.pluck(:name)).to contain_exactly("Core", "Fees", "Income")
    end
  end

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

  describe "password complexity" do
    it "accepts a password with upper, lower, digit, and a special character" do
      expect(build(:user, password: "Correct-Horse-Battery-9")).to be_valid
    end

    it "rejects a password missing an uppercase letter" do
      expect(build(:user, password: "correct-horse-battery-9")).not_to be_valid
    end

    it "rejects a password missing a digit" do
      expect(build(:user, password: "Correct-Horse-Battery")).not_to be_valid
    end

    it "rejects a password missing a special character" do
      expect(build(:user, password: "CorrectHorseBattery9")).not_to be_valid
    end

    it "rejects a password below the minimum length even if otherwise complex" do
      expect(build(:user, password: "Ab9!")).not_to be_valid
    end
  end

  describe "#short_name" do
    it "is first name plus last initial when both are present" do
      user = build(:user, first_name: "Marta", last_name: "Berg")

      expect(user.short_name).to eq("Marta B.")
    end

    it "is just the first name when there is no last name" do
      user = build(:user, first_name: "Marta", last_name: nil)

      expect(user.short_name).to eq("Marta")
    end

    it "is nil when there is no first name" do
      user = build(:user, first_name: nil)

      expect(user.short_name).to be_nil
    end
  end
end
