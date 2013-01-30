class HarvestEntryController < ApplicationController
  unloadable

  #TODO: this does not really work, need to set map.permissions correctly?
  #before_filter :authorize
  
  before_filter :make_sure_user_logged_in_and_has_harvest_user_setup

  def index
    #fetch_entries
    #, :conditions => { :created_at => Time.now }
    #fetch_entries(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year)
    
    #only fetch entries for today and for this user
    @did_fetch_new_entries = false
    if HarvestSync.of(User.current.id).find_by_day_of_the_year(Time.now.yday).nil?
      flash[:notice] = l :rm_smc_attempting_to_fetch_new_entries
      @did_fetch_new_entries = true
      error_string = HarvestEntry.fetch_entries User.current.id
      begin
        unless error_string.empty?
          flash[:error] = error_string.to_s 
        end
      rescue 
        @did_fetch_new_entries = false
        flash[:error] = l :rm_smc_please_setup_harvest_user
      end
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

  def harvest_fetch
    #@harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id) 
    #@harvest_entry = HarvestEntry.find(params[:harvest_entry])

    # if request.post?
    #   if params[:harvest_entry] 
    #     #TODO: whitelist paramz and create locked scope...
    #     @harvest_entry.update_attributes params[:harvest_entry]
        
    #     if @harvest_entry.valid?
    #       @harvest_entry.save
    #       flash[:notice] = "#{l(:notice_save_entry)}"
    #       #redirect_to :action => "done"
    #     else
    #       flash[:error] = "#{l(:notice_save_entry_error)}"
    #     end
    #   else
    #     flash[:error] = "#{l(:notice_save_entry_cancel)}"
    #     #redirect_to :action => "done"
    #   end #params[:harvest_entry]
    # end #request.post?

    respond_to do |format|
      format.html { redirect_to :action => 'index'}
      #format.json { render :partial => 'foobar', :layout => false}
    end

  end #harvest_fetch

  def harvest_fetch_day

    if params[:day]
      if params[:day] == 'today'
        flash[:notice] = "UPDATING TDAY!"
        @did_fetch_new_entries = false
        fetch_entries_for_today
      end
    end 

    respond_to do |format|
      format.html { redirect_to :action => 'index'}
      #format.json { render :partial => 'foobar', :layout => false}
    end

  end

  def harvest_fetch_week
    
    @did_fetch_new_entries = true
    myFlashNotice = ''
    for i in 0..7 do 
      #myFlashNotice << " day #{i} : "
      myFlashNotice << HarvestEntry.fetch_entries(User.current.id, (Time.now.yday - i))
    end
    begin
      unless myFlashNotice.empty?
        flash[:error] = myFlashNotice.to_s 
      end
    rescue 
      @did_fetch_new_entries = false
      flash[:error] = l :rm_smc_please_setup_harvest_user
    end



    respond_to do |format|
      format.html { redirect_to :action => 'index'}
      #format.json { render :partial => 'foobar', :layout => false}
    end

  end

  
  private
  def make_sure_user_logged_in_and_has_harvest_user_setup
    
    #and check to see if there is a HarvestUser
    unless HarvestUser.find_by_redmine_user_id(User.current.id)
      flash[:error] = l :rm_smc_please_setup_harvest_user
      #make sure we're not already there.
      unless Rails.application.routes.recognize_path harvest_user_path
        redirect_to harvest_user_path 
        return false
      end
    end

    unless User.current.logged?
      flash[:error] = l(:rm_smc_please_login)
      redirect_to signin_path 
      return false
    end

  end

  def fetch_entries_for_today
    @did_fetch_new_entries = true
    error_string = HarvestEntry.fetch_entries User.current.id
    begin
      unless error_string.empty?
        flash[:error] = error_string.to_s 
      end
    rescue 
      @did_fetch_new_entries = false
      flash[:error] = l :rm_smc_please_setup_harvest_user
    end
  end

end #class
