require "rails_helper"

RSpec.describe "Dashboard" do
  it "redirects to sign in when logged out" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "is reachable once signed in" do
    sign_in create(:user)

    get root_path

    expect(response).to have_http_status(:ok)
  end
end
