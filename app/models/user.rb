class User < ApplicationRecord
  has_many :votes
  has_many :ranked_works, through: :votes, source: :work
  has_many :works

  validates :username, uniqueness: true, presence: true
  validates :uid, presence: true

  def self.build_user(auth_hash)
    user = User.new
    user.uid = auth_hash[:uid]
    user.provider = "github"
    user.username = auth_hash["info"]["name"]
    user.email = auth_hash["info"]["email"]
    return user
  end

  def is_owner?(work)
    self.id == work.user_id ? true : false
  end
end
