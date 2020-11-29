require "test_helper"

describe Work do
  describe "relations" do
    it "has a list of votes" do
      album = works(:album)
      expect(album).must_respond_to :votes
      album.votes.each do |vote|
        expect(vote).must_be_kind_of Vote
      end
    end

    it "has a list of voting users" do
      album = works(:album)
      expect(album).must_respond_to :ranking_users
      album.ranking_users.each do |user|
        expect(user).must_be_kind_of User
      end
    end
  end

  describe "validations" do
    let(:user) { User.create!(username: "test user", uid: 123456) }
    it "allows the three valid categories" do
      valid_categories = ["album", "book", "movie"]
      valid_categories.each do |category|
        work = Work.new(title: "test", category: category, user: user)
        expect(work.valid?).must_equal true
      end
    end

    it "fixes almost-valid categories" do
      categories = ["Album", "albums", "ALBUMS", "books", "mOvIeS"]
      categories.each do |category|
        work = Work.new(title: "test", category: category, user: user)
        expect(work.valid?).must_equal true
        expect(work.category).must_equal category.singularize.downcase
      end
    end

    it "rejects invalid categories" do
      invalid_categories = ["cat", "dog", "phd thesis", 1337, nil]
      invalid_categories.each do |category|
        work = Work.new(title: "test", category: category, user: user)
        expect(work.valid?).must_equal false
        expect(work.errors.messages).must_include :category
      end
    end

    it "requires a title" do
      work = Work.new(category: "ablum", user: user)
      expect(work.valid?).must_equal false
      expect(work.errors.messages).must_include :title
    end

    it "requires unique names w/in categories" do
      category = "album"
      title = "test title"
      work1 = Work.new(title: title, category: category, user: user)
      work1.save!

      work2 = Work.new(title: title, category: category, user: user)
      expect(work2.valid?).must_equal false
      expect(work2.errors.messages).must_include :title
    end

    it "does not require a unique name if the category is different" do
      user
      title = "test title"
      work1 = Work.new(title: title, category: "album", user: user)
      work1.save!

      work2 = Work.new(title: title, category: "book", user: user)
      expect(work2.valid?).must_equal true
    end

    it 'requires a user' do
      category = "album"
      title = "test title"
      work = Work.new(title: title, category: category)
      expect(work.valid?).must_equal false
    end
  end

  describe "vote_count" do
    before do
      @user = User.create!(username: "test user", uid: 123456)
    end
    it "defaults to 0" do
      work = Work.create!(title: "test title", category: "movie", user: @user)
      expect(work).must_respond_to :vote_count
      expect(work.vote_count).must_equal 0
    end

    it "tracks the number of votes" do
      work = Work.create!(title: "test title", category: "movie", user: @user)
      4.times do |i|
        user = User.create!(username: "user#{i}", uid: rand(10000..99999))
        Vote.create!(user: user, work: work)
      end
      expect(work.vote_count).must_equal 4
      expect(Work.find(work.id).vote_count).must_equal 4
    end
  end

  describe "top_ten" do
    before do
      # TODO DPR: This runs pretty slow. Fixtures?
      # Create users to do the voting
      test_users = []
      20.times do |i|
        test_users << User.create!(username: "user#{i}", uid: rand(10000..99999))
      end

      # Create media to vote upon
      @user = User.create!(username: "test user", uid: 123456)
      Work.where(category: "movie").destroy_all
      8.times do |i|
        work = Work.create!(category: "movie", title: "test movie #{i}", user: @user)
        vote_count = rand(test_users.length)
        test_users.first(vote_count).each do |user|
          Vote.create!(work: work, user: user)
        end
      end


    end

    it "returns a list of media of the correct category" do
      movies = Work.top_ten("movie")
      expect(movies.length).must_equal 8
      movies.each do |movie|
        expect(movie).must_be_kind_of Work
        expect(movie.category).must_equal "movie"
      end
    end

    it "orders media by vote count" do
      movies = Work.top_ten("movie")
      previous_vote_count = 100
      movies.each do |movie|
        expect(movie.vote_count).must_be :<=, previous_vote_count
        previous_vote_count = movie.vote_count
      end
    end

    it "returns at most 10 items" do
      movies = Work.top_ten("movie")
      expect(movies.length).must_equal 8

      Work.create(title: "phase 2 test movie 1", category: "movie", user: @user)
      expect(Work.top_ten("movie").length).must_equal 9

      Work.create(title: "phase 2 test movie 2", category: "movie", user: @user)
      expect(Work.top_ten("movie").length).must_equal 10

      Work.create(title: "phase 2 test movie 3", category: "movie", user: @user)
      expect(Work.top_ten("movie").length).must_equal 10
    end
  end
end
