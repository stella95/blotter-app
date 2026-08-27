require "rails_helper"

RSpec.describe "Categories" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /categories" do
    it "lists only the current user's categories" do
      get categories_path

      expect(response.body).to include("Core")
      expect(response.body).to include("Fees")
    end
  end

  describe "POST /categories" do
    it "creates a category and redirects to the index" do
      expect {
        post categories_path, params: { category: { name: "Speculative", color: "#8a3f6d" } }
      }.to change(user.categories, :count).by(1)

      expect(response).to redirect_to(categories_path)
    end

    it "re-renders the form on invalid input" do
      expect {
        post categories_path, params: { category: { name: "", color: "#8a3f6d" } }
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /categories/:id" do
    it "deletes the category without touching the line items it tagged" do
      category = create(:category, user:)
      line_item = create(:entry_line_item, entry: create(:entry, portfolio: create(:portfolio, user:)), categories: [ category ])

      expect {
        delete category_path(category)
      }.to change(Category, :count).by(-1)

      expect(response).to redirect_to(categories_path)
      expect(EntryLineItem.exists?(line_item.id)).to be true
    end

    it "will not delete another user's category" do
      other_category = create(:category, user: create(:user))

      delete category_path(other_category)

      expect(response).to have_http_status(:not_found)
      expect(Category.exists?(other_category.id)).to be true
    end
  end
end
