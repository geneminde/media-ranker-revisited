require "test_helper"

describe UsersController do
  describe 'auth_callback' do
    it "logs in an existing user and redirects to root" do
      start_count = User.count
      user = users(:dan)

      perform_login(user)
      must_redirect_to root_path

      _(session[:user_id]).must_equal user.id
      _(User.count).must_equal start_count
    end

    it "creates an account for a new user and redirects to root" do
      start_count = User.count
      user = User.new(provider: "github", uid: 112233, email: "email@email.com", username: "Kitty")

      perform_login(user)
      must_redirect_to root_path

      user = User.find_by(uid: 112233, provider: "github")
      expect(session[:user_id]).must_equal user.id

      _(User.count).must_equal start_count + 1
    end

    it "redirects to the login route if given invalid user data" do
      start_count = User.count
      user = User.new(provider: "github", uid: nil, email: "my_email@me.com", username: "me")

      perform_login(user)
      must_redirect_to root_path

      user = User.find_by(uid: nil, provider: "github")
      expect(user).must_equal nil
      expect(session[:user_id]).must_equal nil
      expect(User.count).must_equal start_count
    end
  end
end
