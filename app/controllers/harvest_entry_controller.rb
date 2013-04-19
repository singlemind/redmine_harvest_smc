class HarvestEntryController < ApplicationController
  unloadable
  
  before_filter :make_sure_user_logged_in_and_has_harvest_user_setup

  def index

    if params[:status]
      if params[:status] == 'destroyed'
        # unscoped could mean bad juju...
        @harvest_entries = HarvestEntry.unscoped.of(User.current.id).status(params[:status].to_s).order(:status => :desc)
      else 
        @harvest_entries = HarvestEntry.of(User.current.id).status(params[:status].to_s).order(:status => :desc)
      end
    elsif User.current.admin? 
        logger.info "~~~~~~~~~~~~~ HARVEST ENTRY GETTING ALL FOR ADMIN!"
        @harvest_entries = HarvestEntry.all
    else 
      logger.info "~~~~~~~~~~~~~ HARVEST ENTRY ELSE REG USER!"
      @harvest_entries = HarvestEntry.of(User.current.id).order(:status => :desc)
    end

  end

  def harvest_user

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

    HarvestEntry.fetch_projects User.current.id
    HarvestEntry.fetch_tasks User.current.id

    @harvest_settings = HarvestSettings.all

    @projects = HarvestProject.active_only.uniq_project.collect{|p| p.project_name}
    @tasks = HarvestTask.uniq_task.collect{|t| t.task_name}
    @notes = HarvestEntry.uniq_notes.collect{|n| n.notes}
    @notes.reject! { |n| n.match /\d/ }

    if request.post? 
      if params['new_settings']
        #logger.info '^^^^^^^^^^^^^^^^^^^^^^  NEW NEW NEW SETTING SETTING SETTINGZ'
        #logger.info params.inspect
        
        s = HarvestSettings.new 
        s.redmine_user_id = User.current.id 
        
        s.project        = params['new_settings']['redmine_harvest_smc_project'] unless params['new_settings']['redmine_harvest_smc_project'].nil?
        s.task           = params['new_settings']['redmine_harvest_smc_task'] unless params['new_settings']['redmine_harvest_smc_task'].nil?
        s.notes_string   = params['new_settings']['redmine_harvest_smc_notes_string'] unless params['new_settings']['redmine_harvest_smc_notes_string'].nil?
        s.redmine_issue  = params['new_settings']['redmine_harvest_smc_redmine_issue'].to_i unless params['new_settings']['redmine_harvest_smc_redmine_issue'].nil?

        if s.save 
          flash[:notice] = 'Success!'
        else
          flash[:error] = s.errors.full_messages.to_s
        end

        redirect_to harvest_settings_path

      end
    end #req post

    if request.delete?
      begin
        setting = HarvestSettings.find_by_id(params['setting_id'].to_i)
        delete_message = "#{setting.notes_string} destroyed!"
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = 'No such setting id.'
      end

      begin 
        setting.status = 'destroyed'
        setting.save!
        flash[:notice] = delete_message
      rescue Exception => e
        flash[:notice] = "#{e.to_s}"

      end

      redirect_to harvest_settings_path

    end #rew delete
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

      begin
        from = Date.strptime(params[:harvest_entry][:from], '%Y-%m-%d')
        to = Date.strptime(params[:harvest_entry][:to], '%Y-%m-%d')       
      rescue Exception => e
        flash[:error] = "Could not parse date!"
      end
      
      if params[:harvest_entry]["rm_smc_validate_all_users"] == 'on'
        logger.info "------------- VALIDATING ENTRIES FOR ALL USERS!"
        error_string = ""
        
        for i in from..to do          
          HarvestUser.all.each do |user|
            error_string << HarvestEntry.validate_entries_for(user.redmine_user_id, i.yday, i.year, true)
          end 
        end

      else
        if params[:harvest_entry]["rm_smc_validate_force"] == 'on'
          logger.info "------------- VALIDATING ENTRIES USING [[FORCE]] MUHAHA!"
          for i in from..to do 
            #(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year, force_validate = false)
            # TODO: pass the year as a param from the javascript selector!
            HarvestEntry.validate_entries_for(User.current.id, i.yday, i.year, true)
          end
        #TODO: is this elseif depricated? 
        elsif params[:harvest_entry]["rm_smc_checbox_action"] == 'validate'
          for i in from..to do 
            logger.info "------------- VALIDATING ENTRIES!"
            HarvestEntry.validate_entries_for(User.current.id, i.yday)
          end
        end
      end #if rm_smc_validate_all_users
      

      redirect_to :action => "index"
      return
    end

    
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
      logger.info "______-__-_-__-_-_-_ GONNA DESTROY "

      HarvestEntry.destroy_for_each_entry(params[:harvest_entries], User.current.id)

      #flash[:notice] = HarvestEntry.where(:status => params[:status], :id => params[:harvest_entries], :redmine_user_id => User.current.id ).count.to_s
 
      redirect_to :action => "index"
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

end #class
