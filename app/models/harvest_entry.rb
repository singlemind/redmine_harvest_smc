class HarvestEntry < ActiveRecord::Base
  unloadable
  
  STATUS_STRINGS = [ 'new', 'problem', 'matched', 'unmatched', 'flagged', 'reconciled', 'locked' ]
  DESTROYED_STATUS = 'destroyed'
  VALIDATION_STATUS = 'validation'
  SETTINGS_STATUS = 'settings'
  DEFAULT_STATUS = STATUS_STRINGS[0]
  PROBLEM_STATUS = STATUS_STRINGS[1]
  MATCHED_STATUS = STATUS_STRINGS[2] 
  ERROR_INFO_STRINGS = [
    '4-digit issue found in Harvest Entry notes but did not match Redmine issue.', 
    'No 4-digit issue found in Harvest Entry notes.',
    'Could not find a Redmine Time Entry to destroy.'
  ]

  attr_accessor :error_string

  before_save :set_updated_at
  before_create :set_created_at
  
  #DESTROYED_STATUS
  default_scope :conditions => [ "status != '#{DESTROYED_STATUS}'" ]

  scope :of, lambda { |userID|
    where :redmine_user_id => userID
  } 

  scope :status, lambda { |status|
    s = STATUS_STRINGS.include?(status) ? status : DEFAULT_STATUS
    where :status => s
  } 

  scope :for_year_and_day, lambda { |year, day| 
    d = Date.strptime("#{year}-#{day}", "%Y-%j").to_s
    where :spent_at => d
  }

  scope :uniq_notes, select("DISTINCT notes")

  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end

  def self.fetch_entries(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year)
  	force_sync = true 
  	force_timer = false
  	error_string = ""
    redmine_name = User.find(redmine_user_id).name

    harvest_user = HarvestUser.find_by_redmine_user_id(redmine_user_id)
    if (harvest_user.nil?)
      #flash[:error] = "#{l(:no_user_set)}"
      #error_string << l(:no_user_set)
      logger.error "NO USER SET"
      error_string << "NO USER SET"
      return 
    end
    harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password, Setting["plugin_redmine_harvest_smc"]["harvest_subdomain"])

    begin 

    	response = harvest.request "/daily/#{day_of_the_year}/#{year}", :get
      #logger.info  response.body
      xml_doc = Nokogiri::XML(response.body)

			#raise exception if a match is found unless flag=true
			unless force_sync 
				raise "HarvestSync already exists!" if HarvestSync.find_by_day_of_the_year(day_of_the_year)
			end

      harvest_sync = HarvestSync.new
      harvest_sync.day_of_the_year = day_of_the_year
      harvest_sync.year = Time.now.year
      harvest_sync.status = DEFAULT_STATUS
      harvest_sync.for_redmine_user_id = redmine_user_id
      #TODO: map/collect a list of entry ids and save to new field.
      harvest_sync.save!
      
      xml_doc.xpath("//day_entry").each do |entry|
        
        harvest_entry = HarvestEntry.new
      
      	#TODO: attr_accessor for error strings?
        #flash[:notice] = "Harvest entries found: #{xml_doc.xpath("//day_entry").count}"
        
        harvest_entry.harvest_id = entry.xpath("id").text
        harvest_entry.hours = entry.xpath("hours").text
        harvest_entry.hours_without_timer = entry.xpath("hours_without_timer").text
      	
      	unless force_timer 
      		#don't process entries that have a running timer.
        	next if harvest_entry.hours.equal? harvest_entry.hours_without_timer
        end

        begin 
        	#check to see if this entry has a harvest id that already exists in our db. 
          prev_entry = HarvestEntry.find_by_harvest_id(harvest_entry.harvest_id)
          #TODO: dirty record checking...
          next if prev_entry
        #TODO: rescue RecordNotFound err...
        rescue 
          logger.info "NEW ENTRY FOUND"
          #TODO: implement a flag to trigger a dirty record check that scans each 
          #  attribute (listed below) of the entry to check for changes 
        end
        
        harvest_entry.spent_at = entry.xpath("spent_at").text
        harvest_entry.user_id = entry.xpath("user_id").text
        harvest_entry.client = entry.xpath("client").text
        harvest_entry.project_id = entry.xpath("project_id").text
        harvest_entry.project = entry.xpath("project").text
        harvest_entry.task_id = entry.xpath("task_id").text
        harvest_entry.task = entry.xpath("task").text
        harvest_entry.notes = entry.xpath("notes").text
        harvest_entry.status = DEFAULT_STATUS
        harvest_entry.redmine_user_id = redmine_user_id
        harvest_entry.redmine_name = redmine_name
        #hours_match = true if (prev_entry.hours == harvest_entry.hours)
        harvest_entry.save! unless prev_entry
        
        #use .inspect here?...
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
    	# error_string is a attr_accessor 
      error_string << "#{l(:harvest_api_error)}: #{e} "
    end 
    return error_string    
  end #fetch_entries

  #TODO: feed status param, 
  def self.set_time_for_all_entries(userID = nil, status = 'matched', redmine_user_id = userID)
  	
    #TODO: begin/rescue?

    harvest_entries = HarvestEntry.find(:all, :conditions => { :status => status } )

  	harvest_entries.each do |entry|
  		redmine_issue_id = entry.redmine_issue_id.to_s.match /\d{4}/

  		#next unless redmine_issue_id
      #TODO: set the status of the entry as :unmatched
      if redmine_issue_id
        user = User.find(entry.redmine_user_id)
    		issue = Issue.find(redmine_issue_id.to_s)
        project = issue.project
        #TODO: reflect what Harvest Has?
        activity = TimeEntryActivity.find_by_name('Development')

        #TODO: export time format as settings string?
        te = TimeEntry.create(:spent_on => Date.strptime(entry.spent_at, '%Y-%m-%d'),
                            :hours    => entry.hours,
                            :issue    => issue,
                            :project  => project,
                            :user     => user,
                            :activity => activity,
                            :comments => entry.notes.mb_chars[0..255].strip.to_s) # Truncate comments to 255 charz
        te.save!
        #UPDATE TIME IF THERE IS AN ESTIMATED VALUE
        if issue.estimated_hours
          #isssue.reload
          issue.done_ratio = ((issue.time_entries.collect{|i| i.hours}.sum / issue.estimated_hours)*100).round
          issue.save
         end

        entry.status = "complete"
        entry.redmine_time_entry_id = te.id
      else 
        entry.status = "problem"
        entry.status_info = ERROR_INFO_STRINGS[1]
      end  
      entry.save!
      
  	end 

  end #end self.set_time_for_each_entry

  # hey look at that, if you toss an [ a, r, r, a, y ] at a col name active record uses a WHERE IN
  def self.update_rm_id_for_each_entry(entries = [], userID = nil, status = DEFAULT_STATUS )

    entry = HarvestEntry.where(:status => status, :id => entries, :redmine_user_id => userID ).each do |e|
      #TODO: export regex as settings string...
      redmine_issue_id = e.notes.match /\d{4}/
      if redmine_issue_id
        e.redmine_issue_id = redmine_issue_id[0].to_i
        e.status = 'matched'
        unless Issue.find_by_id(redmine_issue_id[0].to_i)
          e.status = 'problem'
          e.status_info = ERROR_INFO_STRINGS[0]
        end
      else 
        #TODO: internal status?
        e.status_info = ERROR_INFO_STRINGS[1]
        e.status = 'problem'
      end
      e.save!
    end

    return entry
  end #update_rm_id_for_each_entry

  def self.update_rm_id_for_all_entries(userID = nil, status = DEFAULT_STATUS)
    entry = HarvestEntry.where(:status => status, :redmine_user_id => userID ).each do |e|
      #TODO: export regex as settings string...
      redmine_issue_id = e.notes.match /\d{4}/
      if redmine_issue_id
        e.redmine_issue_id = redmine_issue_id[0].to_i
        e.status = 'matched'
        unless Issue.find_by_id(redmine_issue_id[0].to_i)
          e.status_info = ERROR_INFO_STRINGS[0]
          e.status = 'problem'
        end
      else 
        #TODO: internal status?
        e.status_info = ERROR_INFO_STRINGS[1]
        e.status = 'problem'
      end
      e.save!
    end

  end #update_rm_id_for_all_entries 

  def self.reconcile(userID = nil, status = 'problem')
    
    #logger.info "%%%%%%%%%%%%%%% ABOUT TO RECONCILE!"
    HarvestEntry.update_rm_id_for_all_entries(userID)


    entry = HarvestEntry.where(:status => status, :redmine_user_id => userID ).each do |e|
      
      harvest_settings = HarvestSettings.all
      
      harvest_settings.each do |setting|
        
        unless setting.notes_string.nil?
          #logger.info "%%%%%%%%%%%%%%%% notes_string not nil!"
          if !setting.notes_string.blank? and e.notes =~ /#{Regexp.escape(setting.notes_string)}/
            #logger.info "%%%%%%%%%%%%%%%% MATCHED notes_string!"
            e.redmine_issue_id = setting.redmine_issue
            e.status = MATCHED_STATUS
            #e.status = PROBLEM_STATUS unless Issue.find_by_id(setting.redmine_issue)
            e.save! 
            next
          end
          
        end

        unless setting.project.nil?
          #logger.info "%%%%%%%%%%%%%%%% project not nil!"
          if setting.task.nil?
            #logger.info "%%%%%%%%%%%%%%%% task not nil!"
            #JUST A PROJECT!
            if !setting.project.blank? and e.project =~ /#{Regexp.escape(setting.project)}/
              #logger.info "%%%%%%%%%%%%%%%% MATCHED project!"
              e.redmine_issue_id = setting.redmine_issue
              e.status = MATCHED_STATUS
              #e.status = PROBLEM_STATUS unless Issue.find_by_id(setting.redmine_issue)
              e.save!  
              next
            end
            
          else
            #MUST HAVE A TASK, TOO! CHECK BOTH!
            if !setting.project.blank? and e.project =~ /#{Regexp.escape(setting.project)}/ and !setting.task.blank? and e.task =~ /#{Regexp.escape(setting.task)}/
              #logger.info "%%%%%%%%%%%%%%%% MATCHED project AND task!!"
              e.redmine_issue_id = setting.redmine_issue
              e.status = MATCHED_STATUS
              #e.status = PROBLEM_STATUS unless Issue.find_by_id(setting.redmine_issue)  
              e.save!  
              next
            end
            
          end
          
          
        end
        
        #MUST JUST HAVE A TASK DEFINED...
        unless setting.task.nil?
          #logger.info "%%%%%%%%%%%%%%%% task not nil!"
          if !setting.task.blank? and e.task =~ /#{Regexp.escape(setting.task)}/
            #logger.info "%%%%%%%%%%%%%%%% MATCHED just task!"
            e.redmine_issue_id = setting.redmine_issue
            e.status = MATCHED_STATUS
            #e.status = PROBLEM_STATUS unless Issue.find_by_id(setting.redmine_issue)  
            e.save!  
            next
          end

        end
        #TODO: status_info
        #e.status = 'problem' if e.redmine_issue_id.blank?
        #logger.info "%%%%%%%%%%%% END OF SETTINGS!"

      end
      
    end

    HarvestEntry.set_time_for_all_entries(userID)

  end

  #TODO: method that validates all entries in Redmine still exist in Harvest
  def self.validate_entries_for(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year, force_validate = false)


    error_string = ""
    redmine_name = User.find(redmine_user_id).name

    harvest_user = HarvestUser.find_by_redmine_user_id(redmine_user_id)
    if (harvest_user.nil?)
      #flash[:error] = "#{l(:no_user_set)}"
      #error_string << l(:no_user_set)
      logger.error "NO USER SET"
      error_string << "NO USER SET"
      return 
    end
    harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password, Setting["plugin_redmine_harvest_smc"]["harvest_subdomain"])

    begin 
      logger.info "CALLING HARVEST API  /daily/#{day_of_the_year}/#{year}"
      response = harvest.request "/daily/#{day_of_the_year}/#{year}", :get
      #logger.info  response.body
      xml_doc = Nokogiri::XML(response.body)
    

      harvest_sync = HarvestSync.new
      harvest_sync.day_of_the_year = day_of_the_year
      harvest_sync.year = year
      harvest_sync.status = VALIDATION_STATUS
      harvest_sync.for_redmine_user_id = redmine_user_id
      #TODO: map/collect a list of entry ids and save to new field.
      
      harvest_day = xml_doc.xpath("//day_entry").collect{|e| e.xpath("hours").text.to_f }
      harvest_sync.harvest_day_total_entries = harvest_day.count
      harvest_sync.harvest_day_total_time = harvest_day.sum

      redmine_day = HarvestEntry.of(redmine_user_id).for_year_and_day(year, day_of_the_year)
      harvest_sync.redmine_day_total_issues = redmine_day.count
      harvest_sync.redmine_day_total_time = redmine_day.collect{|h| h.hours.to_f}.sum.round(2)

      
      total_entries_diff = harvest_sync.harvest_day_total_entries == harvest_sync.redmine_day_total_issues
      total_time_diff = harvest_sync.harvest_day_total_time.round(2) == harvest_sync.redmine_day_total_time

      logger.info "YEAR: #{year}, DAY_OF_THE_YEAR: #{day_of_the_year}, TOTAL_ENTRIES_DIFF: #{total_entries_diff}, TOTAL_TIME_DIFF: #{total_time_diff}"
      logger.info "HARVEST_DAY_TOTAL_ENTRIES: #{harvest_sync.harvest_day_total_entries}, REDMINE_DAY_TOTAL_ISSUES: #{harvest_sync.redmine_day_total_issues}"
      logger.info "HARVEST_DAY_TOTAL_TIME: #{harvest_sync.harvest_day_total_time.round(2)}, REDMINE_DAY_TOTAL_TIME: #{harvest_sync.redmine_day_total_time}"

      
      logger.info 
      if !total_entries_diff or !total_time_diff or force_validate
        harvest_sync.status = 'problem'
        #TODO: status_info?
        harvest_sync.save!
        # is there a problem? drop & fetch day. (ACCOUNT FOR TimeEntries!)

        to_destroy = HarvestEntry.for_year_and_day(year, day_of_the_year).collect{|e| e.id}
        logger.warn "GOING TO DESTROY #{to_destroy.count} RECORDS OF USER: #{redmine_user_id}. INSPECT: #{to_destroy.inspect}" unless to_destroy.blank?

        HarvestEntry.destroy_for_each_entry(to_destroy, redmine_user_id)

        # NOW RECREATE ENTRIES FOR THE DAYS. BLAM! N\'SYNC!  
        #  but srsly, this might not be necessary, as we could just call the fetch method 
        #   to restart the check, process, validation cycle?
        xml_doc.xpath("//day_entry").each do |entry|
        
          harvest_entry = HarvestEntry.new

          harvest_entry.harvest_id          = entry.xpath("id").text
          harvest_entry.hours               = entry.xpath("hours").text
          harvest_entry.hours_without_timer = entry.xpath("hours_without_timer").text
          
          harvest_entry.spent_at            = entry.xpath("spent_at").text
          harvest_entry.user_id             = entry.xpath("user_id").text
          harvest_entry.client              = entry.xpath("client").text
          harvest_entry.project_id          = entry.xpath("project_id").text
          harvest_entry.project             = entry.xpath("project").text
          harvest_entry.task_id             = entry.xpath("task_id").text
          harvest_entry.task                = entry.xpath("task").text
          harvest_entry.notes               = entry.xpath("notes").text
          harvest_entry.status              = DEFAULT_STATUS
          harvest_entry.redmine_user_id     = redmine_user_id
          harvest_entry.redmine_name        = redmine_name

          harvest_entry.save! 

        end #each

        harvest_sync.status = 'complete'
        harvest_sync.save!

        #call sync to update 'new' entries.
        logger.info "GOING TO FETCH ENTRIES!"
        fetch_entries_from_to(redmine_user_id, day_of_the_year, day_of_the_year)
        

        #fetch_entries( redmine_user_id, day_of_the_year, year )
        #update_rm_id_for_all_entries
        #set_time_for_all_entries

      end #if _diff and whatnot
    
      reconcile(redmine_user_id)

      #PHEW! we just got through a lot, mmm... 

    rescue Exception => e
      # error_string is a attr_accessor 
      error_string << "#{l(:harvest_api_error)}: #{e} "
    end 
    return error_string  
  end #validate_entries



  def self.destroy_for_each_entry (entries = [], userID = nil)
    entries = HarvestEntry.where( :id => entries, :redmine_user_id => userID ).each do |entry|
      # check to see if there is a time entry
      unless entry.redmine_time_entry_id.blank?
        begin 
          TimeEntry.find(entry.redmine_time_entry_id).destroy
        rescue Exception => e
          logger.error "CAUGHT EXCEPTION: #{e}"
          entry.status_info = ERROR_INFO_STRINGS[2]
        end
      end #unless
      
      entry.status = DESTROYED_STATUS
      entry.save!

    end #entries
  end

  def self.fetch_entries_from_to (userID = nil, from = Time.now.yday, to = Time.now.yday )
    myFlashNotice = []
    for i in from..to do 
      #myFlashNotice << " day #{i} : "
      myFlashNotice << HarvestEntry.fetch_entries(userID, i)
    end

    return myFlashNotice
  end

  def self.fetch_projects( redmine_user_id )

    error_string = ""
    redmine_user = User.find(redmine_user_id)
    harvest_user = HarvestUser.find_by_redmine_user_id(redmine_user_id)

    if harvest_user.nil?
      #flash[:error] = "#{l(:no_user_set)}"
      #error_string << l(:no_user_set)
      logger.error "NO USER SET"
      error_string << "NO USER SET"
      return 
    end

    return error_string << "NOT AN ADMIN" if harvest_user.is_harvest_admin==false

    check_harvest_admin_status = harvest_user.is_harvest_admin.nil? ? true : false
    
    begin 

      harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password, Setting["plugin_redmine_harvest_smc"]["harvest_subdomain"])

      response = harvest.request "/projects", :get
      #logger.info  response.body
      xml_doc = Nokogiri::XML(response.body)


      harvest_sync = HarvestSync.new

      harvest_sync.year = Time.now.year
      harvest_sync.status = SETTINGS_STATUS
      harvest_sync.for_redmine_user_id = redmine_user_id
      harvest_sync.save!
      
      xml_doc.xpath("//project").each do |project|
        
        harvest_project = HarvestProject.new
      
        #TODO: attr_accessor for error strings?
        #flash[:notice] = "Harvest entries found: #{xml_doc.xpath("//day_entry").count}"
        
        harvest_project.project_id = project.xpath("id").text
       

        begin 
          #check to see if this project has a harvest id that already exists in our db. 
          prev_entry = HarvestProject.find_by_project_id(harvest_project.project_id)
          #TODO: dirty record checking...
          next if prev_entry
        #TODO: rescue RecordNotFound err...
        rescue 
          logger.info "NEW PROJECT FOUND"
        end
        

        harvest_project.project_name = project.xpath("name").text
        harvest_project.project_client_id = project.xpath("client-id").text
        harvest_project.project_code = project.xpath("code").text
        harvest_project.project_notes = project.xpath("notes").text        
        harvest_project.project_active = project.xpath("active").text
        
        harvest_project.save! unless prev_entry
        
      end #each
      
    rescue Exception => e
      #could this infer that the user is not an admin?

      # error_string is a attr_accessor 
      logger.error "Harvest API returned 404, seems like this is not an admin user..." if e.to_s.match /404/ 
      harvest_user.is_harvest_admin = false if e.to_s.match /404/ and check_harvest_admin_status
      error_string << "#{l(:harvest_api_error)}: #{e} "
    end 
    return error_string    
  end #fetch_projects

  def self.fetch_tasks( redmine_user_id )

    error_string = ""
    redmine_user = User.find(redmine_user_id)
    harvest_user = HarvestUser.find_by_redmine_user_id(redmine_user_id)

    if harvest_user.nil?
      #flash[:error] = "#{l(:no_user_set)}"
      #error_string << l(:no_user_set)
      logger.error "NO USER SET"
      error_string << "NO USER SET"
      return 
    end

    #TODO: return false and set errors :base
    return error_string << "NOT AN ADMIN" if harvest_user.is_harvest_admin==false

    check_harvest_admin_status = harvest_user.is_harvest_admin.nil? ? true : false
    
    begin 

      harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password, Setting["plugin_redmine_harvest_smc"]["harvest_subdomain"])

      response = harvest.request "/tasks", :get
      #logger.info  response.body
      xml_doc = Nokogiri::XML(response.body)


      harvest_sync = HarvestSync.new

      harvest_sync.year = Time.now.year
      harvest_sync.status = SETTINGS_STATUS
      harvest_sync.for_redmine_user_id = redmine_user_id
      harvest_sync.save!
      
      xml_doc.xpath("//task").each do |task|
        
        harvest_task = HarvestTask.new
      
        #TODO: attr_accessor for error strings?
        #flash[:notice] = "Harvest entries found: #{xml_doc.xpath("//day_entry").count}"
        
        harvest_task.task_id = task.xpath("id").text
       

        begin 
          #check to see if this project has a harvest id that already exists in our db. 
          prev_entry = HarvestTask.find_by_task_id(harvest_task.task_id)
          #TODO: dirty record checking...
          next if prev_entry
        #TODO: rescue RecordNotFound err...
        rescue 
          logger.info "NEW TASK FOUND"
        end
        

        harvest_task.task_name = task.xpath("name").text
        harvest_task.task_deactivated = task.xpath("deactivated").text

        harvest_task.save! unless prev_entry
        
      end #each
      
    rescue Exception => e
      #could this infer that the user is not an admin?

      # error_string is a attr_accessor 
      logger.error "Harvest API returned 404, seems like this is not an admin user..." if e.to_s.match /404/ 
      harvest_user.is_harvest_admin = false if e.to_s.match /404/ and check_harvest_admin_status
      error_string << "#{l(:harvest_api_error)}: #{e} "
    end 
    return error_string    
  end #fetch_tasks

end