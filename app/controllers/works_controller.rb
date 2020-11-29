class WorksController < ApplicationController
  # We should always be able to tell what category
  # of work we're dealing with
  before_action :category_from_work, except: [:root, :index, :new, :create]

  def root
    @albums = Work.best_albums
    @books = Work.best_books
    @movies = Work.best_movies
    @best_work = Work.order(vote_count: :desc).first
  end

  def index
    if @login_user
      @works_by_category = Work.to_category_hash
    else
      flash[:status] = :failure
      flash[:result_text] = "You must be logged in to access this page"
      redirect_to root_path
    end

  end

  def new
    if @login_user
      @work = Work.new
    else
      flash[:status] = :failure
      flash[:result_text] = "You must be logged in to add a work"
      redirect_to root_path
    end
  end

  def create
    if @login_user
      @work = Work.new(media_params)
      @work.user = @login_user
      @media_category = @work.category
      if @work.save
        flash[:status] = :success
        flash[:result_text] = "Successfully created #{@media_category.singularize} #{@work.id}"
        redirect_to work_path(@work)
      else
        flash[:status] = :failure
        flash[:result_text] = "Could not create #{@media_category.singularize}"
        flash[:messages] = @work.errors.messages
        render :new, status: :bad_request
      end
    end
  end

  def show
    if @login_user
      @votes = @work.votes.order(created_at: :desc)
    else
      flash[:status] = :failure
      flash[:result_text] = "You must be logged in to view this page"
      redirect_to root_path
    end

  end

  def edit
    unless session[:user_id] == @work.user_id
      flash[:status] = :failure
      flash[:result_text] = "You must have added this work to edit it"
      redirect_back fallback_location: root_path
    end
  end

  def update
    if @work.update(media_params)
      flash[:status] = :success
      flash[:result_text] = "Successfully updated #{@media_category.singularize} #{@work.id}"
      redirect_to work_path(@work)
    else
      flash.now[:status] = :failure
      flash.now[:result_text] = "Could not update #{@media_category.singularize}"
      flash.now[:messages] = @work.errors.messages
      render :edit, status: :not_found
    end
  end

  def destroy
    if @login_user == @work.user
      @work.destroy
      flash[:status] = :success
      flash[:result_text] = "Successfully destroyed #{@media_category.singularize} #{@work.id}"
      redirect_to root_path
    else
      flash[:status] = :failure
      flash[:result_text] = "You must have added this work to delete it"
      redirect_back fallback_location: root_path
    end
  end

  def upvote
    flash[:status] = :failure
    if @login_user
      vote = Vote.new(user: @login_user, work: @work)
      if vote.save
        flash[:status] = :success
        flash[:result_text] = "Successfully upvoted!"
      else
        flash[:result_text] = "Could not upvote"
        flash[:messages] = vote.errors.messages
      end
    else
      flash[:result_text] = "You must log in to do that"
    end

    # Refresh the page to show either the updated vote count
    # or the error message
    redirect_back fallback_location: work_path(@work)
  end

  private

  def media_params
    params.require(:work).permit(:title, :category, :creator, :description, :publication_year)
  end

  def category_from_work
    @work = Work.find_by(id: params[:id])
    return render_404 unless @work
    @media_category = @work.category.downcase.pluralize
  end
end
