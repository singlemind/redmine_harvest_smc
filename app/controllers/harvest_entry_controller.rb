class HarvestEntryController < ApplicationController
  unloadable

  #TODO: this does not really work, need to set map.permissions correctly?
  #before_filter :authorize
  
  before_filter :make_sure_user_logged_in

  def index
    #fetch_entries
    #, :conditions => { :created_at => Time.now }
    #fetch_entries(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year)

    error_string = HarvestEntry.fetch_entries User.current.id
    
    unless error_string.empty?
      flash[:error] = error_string.to_s 
    end

    @harvest_entries = HarvestEntry.find(:all)
  end

  def harvest_user
    #TODO: implemented forms for encrypting and decrypting user/pass
    @harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id) || HarvestUser.new
    if request.post?
      if params[:harvest_user] 
        
        #@harvest_user.update_attributes params[:harvest_user]
        #not quite as snazzy as update_attributes but will have to do...
        @harvest_user.harvest_username_crypt = params[:harvest_user][:decrypt_username]
        @harvest_user.harvest_password_crypt  = params[:harvest_user][:decrypt_password]
        
        if @harvest_user.valid?
          @harvest_user.save
          flash[:notice] = "#{l(:notice_save_user)}"
          #redirect_to :action => "done"
        else
          flash[:error] = "#{l(:notice_save_user_error)}"
        end
      else
        flash[:error] = "#{l(:notice_save_user_cancel)}"
        #redirect_to :action => "done"
      end #params[:harvest_user]
    end #request.post?
    
  end #harvest_user

  def harvest_update
    @harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id) 
    @harvest_entry = HarvestEntry.find(params[:harvest_entry])

    if request.get? 
      error_string = HarvestEntry.fetch_entries Time.now.yday
      flash[:notice] = "#{error_string}"
    end

    if request.post?
      if params[:harvest_entry] 
        
        @harvest_entry.update_attributes params[:harvest_entry]
        
        if @harvest_entry.valid?
          @harvest_entry.save
          flash[:notice] = "#{l(:notice_save_entry)}"
          #redirect_to :action => "done"
        else
          flash[:error] = "#{l(:notice_save_entry_error)}"
        end
      else
        flash[:error] = "#{l(:notice_save_entry_cancel)}"
        #redirect_to :action => "done"
      end #params[:harvest_entry]
    end #request.post?
  end #harvest_update

  def harvest_update_day
      @harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id) 
      @harvest_entry = HarvestEntry.find(params[:harvest_entry])

      error_string = HarvestEntry.fetch_entries Time.now.yday
      flash[:notice] = "#{error_string}"

  end

  def harvest_update_week
    myFlashNotice = ''
    for i in 0..7 do 
      myFlashNotice << " day #{i} : "
      myFlashNotice << HarvestEntry.fetch_entries(Time.now.yday - i)
    end

    flash[:notice] = "#{myFlashNotice}"

  end

  
  private
  def make_sure_user_logged_in
    unless User.current.logged?
      flash[:error] = l(:rm_smc_please_login)
      redirect_to signin_path
    end
  end

end #class
