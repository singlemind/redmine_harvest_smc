class HarvestEntryController < ApplicationController
  unloadable

  #TODO: this does not really work, need to set map.permissions correctly?
  #before_filter :authorize
  
  before_filter :make_sure_user_logged_in_and_has_harvest_user_setup

  def index
    #fetch_entries
    #, :conditions => { :created_at => Time.now }
    #fetch_entries(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year)
    
    # courtesy fetch entries for today and for this user?? 
    #courtesy_fetch
    @did_fetch_new_entries = false
    
    if params[:status]
      if params[:status] == 'destroyed'
        # unscoped could mean bad juju...
        @harvest_entries = HarvestEntry.unscoped.of(User.current.id).status(params[:status].to_s).order(:status => :desc)
      else 
        @harvest_entries = HarvestEntry.of(User.current.id).status(params[:status].to_s).order(:status => :desc)
      end
      
    else 
      @harvest_entries = HarvestEntry.of(User.current.id).order(:status => :desc)
    end

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

  def harvest_settings

    @harvest_settings = HarvestSettings.of User.current.id
    uniq_for_settings = []
    uniq_for_settings << HarvestEntry.of(User.current.id).uniq_project.collect{|p| p.project}
    uniq_for_settings << HarvestEntry.of(User.current.id).uniq_client.collect{|c| c.client}
    uniq_for_settings << HarvestEntry.of(User.current.id).uniq_task.collect{|t| t.task}

    @uniq_for_settings = uniq_for_settings.flatten.compact #.collect{|p| }
    logger.info "UNIQ_FOR_SETTINGS: #{@uniq_for_settings}"
    #HarvestEntry.of(User.current.id).uniq_project

    if request.post? 
      logger.info '^^^^^^^^^^^^^^^^^^^^^^ POST POST POST POST'
      if params['new_settings']
        logger.info '^^^^^^^^^^^^^^^^^^^^^^  NEW NEW NEW SETTING SETTING SETTINGZ'
        to_save = false
        tmp_arr = []
        params['new_settings'].each_with_index do |new_setting, i|
          logger.info "SETTING #{new_setting}"
          
          
          
          if new_setting[0].match /redmine_harvest_smc_notes_string/
            tmp_arr << new_setting[1] 
            to_save = true
          elsif new_setting[0].match /redmine_harvest_smc_redmine_issue/
            tmp_arr << new_setting[1].to_i 
            to_save = true
          end
          
          if tmp_arr.count > 1 and to_save
            s = HarvestSettings.new 
            s.redmine_user_id = User.current.id 
            s.notes_string = tmp_arr[0]
            s.redmine_issue = tmp_arr[1]
            s.save 
            tmp_arr = []
          end
          
          
        end
        flash[:notice] = 'success' if to_save
      end
    end #req post

    if request.delete?
      #params['settings']
      logger.info '~~~~~~~~~~~~~ DELETE!'
      logger.info "~~~~~~~~~~~~~ #{params.inspect}"
      begin
        setting = HarvestSettings.find(params['setting_id'].to_i)
        delete_message = "#{setting.notes_string} destroyed!"
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = 'No such setting id.'
      end

      begin 
        setting.status = 'destroyed'
        setting.save!
        flash[:notice] = delete_message
      rescue
        flash[:notice] = 'PROBLEM'
      end

      redirect_to harvest_settings_path

    end #rew delete
  end

  def harvest_fetch

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
        fetch_entries_for Time.now.yday
      end
    end 

    respond_to do |format|
      format.html { redirect_to :action => 'index'}
      #format.json { render :partial => 'foobar', :layout => false}
    end

  end

  # UNUSED! 
  def harvest_fetch_week
    
    @did_fetch_new_entries = true
    #throw out the blanks
    myFlashNotice = HarvestEntry.fetch_entries_from_to(User.current.id, (Time.now.yday - 7), Time.now.yday)
    

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
  end #harvest_fetch_week

  # UNUSED!
  def checkbox_action 
    logger.info "_______________ CHECKBOX_ACTION"
    if request.post? and params[:harvest_entry]
      logger.info "____________ #{params[:harvest_entry]["rm_smc_checbox_action"]}"
      if params[:harvest_entry]["rm_smc_checbox_action"] == 'reconcile'
        logger.info "------ reconcile reconcile reconcile!"
        reconcile
      elsif params[:harvest_entry]["rm_smc_checbox_action"] == 'destroy'
        logger.info "------ destroy destroy destroy!"
        destroy
      end

    end
  end

  def reconcile 
    #takes and array of checked paramz and callz HarvetEntry method accordingly.
    logger.warn "----- #{params.inspect}"
    logger.info "_______________ RECONCILE"
    #TODO: case switch for action type 

    #harvest_entries?
      
    if request.post? and params[:harvest_entries]
      #logger.info params.inspect
      params[:status] ||= 'new'
      HarvestEntry.update_rm_id_for_each_entry(params[:harvest_entries], User.current.id, params[:status])
      redirect_to :action => "index"
      return
      #flash[:notice] = HarvestEntry.where(:status => params[:status], :id => params[:harvest_entries], :redmine_user_id => User.current.id ).count.to_s
    end

    if request.post? and params[:harvest_entry] and params[:harvest_entry][:from] and params[:harvest_entry][:to]

      from = params[:harvest_entry][:from]
      to = params[:harvest_entry][:to]
      #myFlashNotice = HarvestEntry.fetch_entries_from_to(User.current.id, from, to)
      
      # begin
      #   unless myFlashNotice.empty?
      #     flash[:error] = myFlashNotice.to_s 
      #   end
      # rescue 
      #   @did_fetch_new_entries = false
      #   flash[:error] = l :rm_smc_please_setup_harvest_user
      # end

      #legacy?
      @did_fetch_new_entries = false

      if params[:harvest_entry]["rm_smc_validate_force"] == 'on'
        logger.info "------------- VALIDATING ENTRIES USING [[FORCE]] MUHAHA!"
        for i in from..to do 
          #(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year, force_validate = false)
          # TODO: pass the year as a param from the javascript selector!
          HarvestEntry.validate_entries_for(User.current.id, i, Time.now.year, true)
        end
      elsif params[:harvest_entry]["rm_smc_checbox_action"] == 'validate'
        for i in from..to do 
          logger.info "------------- VALIDATING ENTRIES!"
          HarvestEntry.validate_entries_for(User.current.id, i)
        end
      end
      redirect_to :action => "index"
      return
    end

    #TODO: trap errz
    
    
    #flash[:notice] = HarvestEntry.where(:status => params[:status], :id => params[:harvest_entries], :redmine_user_id => User.current.id ).count.to_s
    
    #of(User.current.id)
    HarvestEntry.reconcile User.current.id



    logger.info 'NO DATE SPECIFIED!'
    redirect_to :action => "index"


  end

  def destroy 
    logger.warn "------------- #{params.inspect}"
    #TODO: case switch for action type 
    #harvest_entries?
    if params[:harvest_entries]
      #logger.info params.inspect
      logger.info "______-__-_-__-_-_-_ GONNA DESTORYR "

      HarvestEntry.destroy_for_each_entry(params[:harvest_entries], User.current.id)

      #flash[:notice] = HarvestEntry.where(:status => params[:status], :id => params[:harvest_entries], :redmine_user_id => User.current.id ).count.to_s
 
      redirect_to :action => "index"
    end
  end

  def sync_status

    if params[:entries]
      params[:status] ||= 'new'
      HarvestEntry.of(User.current.id).update_rm_id_for_each_entry(params[:entries], User.current.id, params[:status])

    end
  end #sync_status
  
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

  def fetch_entries_for (date = Time.now.yday)
    @did_fetch_new_entries = true
    error_string = HarvestEntry.fetch_entries(User.current.id, date)
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
