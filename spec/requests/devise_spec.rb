require "rails_helper"

RSpec.describe "Devise sign in and sign up" do
  # ApplicationController requires authenticate_user! app-wide, and Devise's
  # own controllers inherit from ApplicationController. Worth pinning down as
  # a regression spec: if that ever stopped resolving safely, sign in itself
  # would be unreachable.
  it "shows the sign in form while logged out, without redirecting" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('action="/users/sign_in"')
  end

  it "shows the sign up form while logged out, without redirecting" do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('action="/users"')
  end

  it "signs a user in and reaches the dashboard" do
    user = create(:user, password: "Correct-Horse-Battery-9")

    post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
  end

  it "does not show the default Signed in successfully flash, the dashboard is confirmation enough" do
    user = create(:user, password: "Correct-Horse-Battery-9")

    post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }
    follow_redirect!

    expect(response.body).not_to include(I18n.t("devise.sessions.signed_in"))
  end

  it "does not show the default Signed out successfully flash either" do
    sign_in create(:user)

    delete destroy_user_session_path
    follow_redirect!

    expect(response.body).not_to include(I18n.t("devise.sessions.signed_out"))
  end

  it "shows the forgot password form" do
    get new_user_password_path

    expect(response).to have_http_status(:ok)
  end

  it "shows the account edit form once signed in" do
    sign_in create(:user)

    get edit_user_registration_path

    expect(response).to have_http_status(:ok)
  end

  it "shows the reset password form given a real token" do
    user = create(:user)
    raw_token = user.send_reset_password_instructions

    get edit_user_password_path(reset_password_token: raw_token)

    expect(response).to have_http_status(:ok)
  end

  describe "email confirmation" do
    it "sends a confirmation email on sign up and blocks sign in until confirmed" do
      expect {
        post user_registration_path, params: {
          user: {
            first_name: "Marta", last_name: "Berg", email: "marta@example.com",
            password: "Correct-Horse-Battery-9",
            password_confirmation: "Correct-Horse-Battery-9"
          }
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      user = User.find_by(email: "marta@example.com")
      expect(user).not_to be_confirmed

      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }
      follow_redirect!

      expect(response.body).to include(I18n.t("devise.failure.unconfirmed"))
    end

    it "allows sign in once the real confirmation link is followed" do
      # Creating the user already triggers Devise's own after_commit callback
      # that generates and emails a confirmation token, unlike reset_password_token
      # this one is stored unhashed, so it can be read directly off the record.
      user = create(:user, :unconfirmed, password: "Correct-Horse-Battery-9")

      get user_confirmation_path(confirmation_token: user.confirmation_token)
      expect(user.reload).to be_confirmed

      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }

      expect(response).to redirect_to(root_path)
    end

    it "shows the resend confirmation form" do
      get new_user_confirmation_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "account lockout" do
    it "locks the account after too many failed attempts, even with the right password afterward" do
      user = create(:user, password: "Correct-Horse-Battery-9")

      Devise.maximum_attempts.times do
        post user_session_path, params: { user: { email: user.email, password: "wrong" } }
      end

      expect(user.reload).to be_access_locked

      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }

      # Paranoid mode deliberately hides that the account is specifically
      # locked, rather than just given the wrong password, otherwise the
      # message itself would confirm the account exists and is near lockout.
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password.")
      expect(response.body).not_to include(I18n.t("devise.failure.locked"))
    end

    it "unlocks the account once the real unlock link is followed" do
      user = create(:user, password: "Correct-Horse-Battery-9")
      # unlock_token is hashed at rest, like reset_password_token, unlike
      # confirmation_token. lock_access! (with unlock_strategy :both) returns
      # the raw token, the same shape as send_reset_password_instructions.
      raw_token = user.lock_access!

      get user_unlock_path(unlock_token: raw_token)
      expect(user.reload).not_to be_access_locked

      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }

      expect(response).to redirect_to(root_path)
    end

    it "shows the resend unlock instructions form" do
      get new_user_unlock_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "sign in tracking" do
    it "records sign in count and IP after a successful sign in" do
      user = create(:user, password: "Correct-Horse-Battery-9")
      expect(user.sign_in_count).to eq(0)

      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }

      expect(user.reload.sign_in_count).to eq(1)
      expect(user.last_sign_in_at).to be_present
      expect(user.last_sign_in_ip).to be_present
    end

    it "shows the last sign in time on the account page, but not the IP" do
      user = create(:user, password: "Correct-Horse-Battery-9")
      post user_session_path, params: { user: { email: user.email, password: "Correct-Horse-Battery-9" } }
      user.reload

      get edit_user_registration_path

      expect(response.body).to include(I18n.l(user.last_sign_in_at, format: :long))
      expect(response.body).not_to include(user.last_sign_in_ip)
    end
  end

  describe "session timeout" do
    it "is configured to 30 minutes of inactivity" do
      expect(Devise.timeout_in).to eq(30.minutes)
    end
  end
end
