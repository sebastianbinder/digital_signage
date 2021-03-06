class SlidesController < ApplicationController
  filter_resource_access additional_collection: [:destroy_multiple, :edit_multiple, :update_multiple, :add_to_signs, :drop_create], additional_member: [:show_editable_content, :fork]
  respond_to :html, except: [:destroy_multiple]
  respond_to :js, only: [:index, :destroy, :destroy_multiple]

  def index
    if current_user.departments.count > 0
      if params[:q].blank?
        # params[:search] = {published_status: :published}  # Default to only showing published slides
      end

      @q = Slide.search(params[:q])
      @slides = @q.result(distinct: true).published_status(params[:published_status]).includes(:department)

      if params[:all_signs].blank?
        @slides = @slides.joins(department: :department_users).where('department_users.user_id = ?', current_user.id)
      end

      @slides = @slides.page(params[:page]).per(20)

      @signs = Sign.with_permissions_to(:edit_slots).order('signs.title')

      # create new slide for dropdown form.
      @slide = Slide.new

      respond_with(@slides) do |format|
        format.js do
          render partial: 'slides' unless params["_"] # Otherwise if infinites scroll render index.js.erb
        end
      end
    else
      flash[:danger] = 'You do not have access to that page'
      redirect_to signs_path
    end
  end

  def show
    render :edit if permitted_to?(:edit, @slide)
  end

  def show_editable_content
    # This is the page where editable content is dislayed to the signage client
    render :layout => false
  end

  def edit
    redirect_to @slide
  end

  def create
    @slide.publish_at ||= Time.now

    case params[:options]
    when 'upload'
      @slide.slide_type = Slide::UPLOAD
      @slide.html_url = ''
    when 'link'
      @slide.slide_type = Slide::LINK
      @slide.content = nil
    when 'editor'
      @slide.slide_type = Slide::EDITOR
      @slide.html_url = ''
      @slide.content = nil
    end

    if @slide.save
      flash[:notice] = 'Slide created'
      respond_with @slide
    else
      flash[:error] = @slide.errors.full_messages.first
      redirect_to :back
    end
  end

  def fork
    new_slide = @slide.dup
    new_slide.content = @slide.content
    new_slide.department = current_user.departments.first
    if new_slide.save
      flash[:info] = 'Slide was forked!'
      redirect_to new_slide
    else
      flash[:error] = 'There was a problem forking this slide.'
      redirect_to @slide
    end
  end

  def update
    if @slide.update_attributes(slide_params)
      flash[:notice] = 'Slide updated'
    end
    respond_with @slide
  end

  def destroy
    if @slide.destroy
      flash[:notice] = 'Slide deleted'
    end
    respond_with @slide
  end

  def destroy_multiple
    Slide.find(params[:slide]).each { |slide| slide.destroy if permitted_to? :destroy, slide }
    render :nothing => true
  end

  def edit_multiple
    @slides = current_user.slides.find(params[:s_ids])
    @slottable_signs = current_user.signs
  end
  def update_multiple
    @slides = current_user.slides.find(params[:slide_ids])
    @slides.each do |slide|
      slide.update_attributes!(slide_params.reject {|k,v| v.blank? }) # only update values that aren't blank
    end
    flash[:notice] = "Updated slides!"
    redirect_to slides_path
  end

  def add_to_signs
    signs = current_user.signs.find(params[:sign_ids])  # signs already come as an array
    slides = Slide.find(params[:slide_ids].split(','))  # slides come as a comma seperated string

    # Add new slides to each selected sign
    signs.each do |sign|
      sign.slides << slides
    end

    flash[:notice] = "#{slides.length} Slides added to the following signs - #{signs.map{|s| view_context.link_to(s.title, s) }.join(', ')}".html_safe

    redirect_to slides_url
  end

  def drop_create
    slide = Slide.from_drop params[:file], current_user.departments.first
    slide.slide_type = Slide::UPLOAD

    if slide.save
      flash[:notice] = "Slide has been created"
      render :json => { result: 'success' }
    else
      flash[:danger] = "There was a problem creating the slide"
      render :json => { result: 'error' }
    end
  end

  private

    # Override DeclarativeAuthorization method
    def new_slide_from_params
      if params[:slide]
        @slide = Slide.new(slide_params)
      else
        @slide = Slide.new
      end
    end

    # Only allow a trusted parameter "white list" through.
    def slide_params
      params.require(:slide).permit(
        :title, :interval, :department_id, :publish_at, :unpublish_at,
        :html_url, :content, :content_cache, :editable_content,
        :sign_ids,  # for creating a new slide from the sign page.
        :is_editor, :background_color, :overlay_color,
        schedules_attributes: [:when, :active, :id, :_destroy], slots_attributes: [:sign_id, :id, :_destroy]
      )
    end
end