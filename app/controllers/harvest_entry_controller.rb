class HarvestEntryController < ApplicationController
  unloadable

  #TODO: this does not really work, need to set map.permissions correctly?
  #before_filter :authorize
  
  def index
    fetch_entries
    #, :conditions => { :created_at => Time.now }
    @harvest_entry = HarvestEntry.find(:all)
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
  
  def fetch_entries
    harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id)
    if (harvest_user.nil?)
      flash[:error] = "#{l(:no_user_set)}"
      return 
    end
    harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password)

    begin 
      response = harvest.request '/daily', :get
      #logger.info  response.body
      xml_doc = Nokogiri::XML(response.body)
      
      harvest_sync = HarvestSync.new
      harvest_sync.day_of_the_year = Time.now.yday
      harvest_sync.year = Time.now.year
      harvest_sync.status = "new"
      harvest_sync.save!
      
      xml_doc.xpath("//day_entry").each do |entry|
        
        harvest_entry = HarvestEntry.new
      
        flash[:notice] = "Harvest entries found: #{xml_doc.xpath("//day_entry").count}"
        
        harvest_entry.harvest_id = entry.xpath("id").text
        harvest_entry.hours = entry.xpath("hours").text
        harvest_entry.hours_without_timer = entry.xpath("hours_without_timer").text
      	
        begin 
          #debugger
          prev_entry = HarvestEntry.find_by_harvest_id(harvest_entry.harvest_id)
          next if prev_entry
        rescue 
          logger.info "NEW ENTRY FOUND"
          #DONCHA WORRY ABBOUT IT!
        end
        
        harvest_entry.spent_at = entry.xpath("spent_at").text
        harvest_entry.user_id = entry.xpath("user_id").text
        harvest_entry.client = entry.xpath("client").text
        harvest_entry.project_id = entry.xpath("project_id").text
        harvest_entry.project = entry.xpath("project").text
        harvest_entry.task_id = entry.xpath("task_id").text
        harvest_entry.task = entry.xpath("task").text
        harvest_entry.notes = entry.xpath("notes").text
        
        #hours_match = true if (prev_entry.hours == harvest_entry.hours)
        harvest_entry.save! unless (prev_entry)
        
        #logger.info  "id: #{entry.xpath("id").text} | "
        #logger.info  "hours: #{entry.xpath("hours").text} | "
        #logger.info  "hours_without_timer: #{entry.xpath("hours_without_timer").text} | "
        #logger.info  "spent_at: #{entry.xpath("spent_at").text} | "
        #logger.info  "user_id: #{entry.xpath("user_id").text} | "
        #logger.info  "client: #{entry.xpath("client").text} | "
        #logger.info  "project_id: #{entry.xpath("project_id").text} | "
        #logger.info  "project: #{entry.xpath("project").text} | "
        #logger.info  "task_id #{entry.xpath("task_id").text} | "
        #logger.info  "task: #{entry.xpath("task").text} | "
        #logger.info  "notes: #{entry.xpath("notes").text} | "
      end #each
      
    rescue Exception => e
      flash[:error] = "#{l(:harvest_api_error)}: #{e}"
    end 
    
  end #fetch_entries
  
end #class
