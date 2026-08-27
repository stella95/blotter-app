require "rails_helper"

RSpec.describe "Portfolios" do
  let(:user) { create(:user) }

  describe "authentication" do
    it "redirects to sign in when logged out" do
      get portfolios_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /portfolios" do
    before { sign_in user }

    it "lists only the current user's active portfolios" do
      mine = create(:portfolio, user:, name: "Retirement")
      create(:portfolio, user:, name: "Old").archive!
      create(:portfolio, user: create(:user), name: "Someone else's")

      get portfolios_path

      expect(response.body).to include(mine.name)
      expect(response.body).not_to include("Old")
      expect(response.body).not_to include("Someone else's")
    end
  end

  describe "GET /portfolios/:id" do
    before { sign_in user }

    it "shows a portfolio the user owns" do
      portfolio = create(:portfolio, user:)

      get portfolio_path(portfolio)

      expect(response).to have_http_status(:ok)
    end

    it "404s for another user's portfolio" do
      other_portfolio = create(:portfolio, user: create(:user))

      get portfolio_path(other_portfolio)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /portfolios" do
    before { sign_in user }

    it "creates a portfolio and redirects to it" do
      expect {
        post portfolios_path, params: { portfolio: { name: "Crypto" } }
      }.to change { user.portfolios.count }.by(1)

      expect(response).to redirect_to(portfolio_path(user.portfolios.last))
    end

    it "re-renders the form on invalid input" do
      expect {
        post portfolios_path, params: { portfolio: { name: "" } }
      }.not_to change(Portfolio, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /portfolios/:id" do
    before { sign_in user }

    it "updates a portfolio the user owns" do
      portfolio = create(:portfolio, user:, name: "Old name")

      patch portfolio_path(portfolio), params: { portfolio: { name: "New name" } }

      expect(portfolio.reload.name).to eq("New name")
    end
  end

  describe "PATCH /portfolios/:id/archive" do
    before { sign_in user }

    it "archives the portfolio instead of exposing archived_at directly" do
      portfolio = create(:portfolio, user:)

      patch archive_portfolio_path(portfolio)

      expect(portfolio.reload).to be_archived
    end
  end

  describe "DELETE /portfolios/:id" do
    before { sign_in user }

    it "deletes a portfolio with no history" do
      portfolio = create(:portfolio, user:)

      expect { delete portfolio_path(portfolio) }.to change(Portfolio, :count).by(-1)
      expect(response).to redirect_to(portfolios_path)
    end

    it "refuses to delete a portfolio with entries" do
      portfolio = create(:portfolio, user:)
      create(:entry, portfolio:)

      expect { delete portfolio_path(portfolio) }.not_to change(Portfolio, :count)
      expect(response).to redirect_to(portfolio_path(portfolio))
    end
  end
end
