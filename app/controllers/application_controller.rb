# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  before_filter :set_current_user

  include SslRequirement if defined? SslRequirement

  helper :all # include all helpers, all the time

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def flash_announcements_for(user=nil)
    user ||= current_user
    Announcement.current.after(user.last_sign_in_at).each do |announcement|
      flash.now[:announce] = announcement.announcement
    end
  end

  protected
  
    def set_current_user
      Authorization.current_user = current_user
    end
  
    def permission_denied
    
      flash[:error] = 'Access denied' unless current_user.nil?
    
      if permitted_to? AppConfig.routing.default.action.to_sym, AppConfig.routing.default.controller.to_sym
        redirect_to :back rescue redirect_to root_url
      elsif !current_user.nil?
        redirect_to destroy_user_session_url
      else
        redirect_to new_user_session_url
      end
      
    end
  
end
