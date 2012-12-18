class HarvestEntry < ActiveRecord::Base
  unloadable
  
  attr_accessor :error_string

  before_save :set_updated_at
  before_create :set_created_at
  
  def self.fetch_entries(redmine_user_id, day_of_the_year = Time.now.yday, year = Time.now.year)
  	force_reload = false
  	force_sync = true 
  	force_timer = false
  	new_status = "new"
  	error_string = ""

    harvest_user = HarvestUser.find_by_redmine_user_id(redmine_user_id)
    if (harvest_user.nil?)
      #flash[:error] = "#{l(:no_user_set)}"
      #error_string << l(:no_user_set)
      logger.error "NO USER SET"
      error_string << "NO USER SET"
      return 
    end
    harvest = HarvestClient.new(harvest_user.decrypt_username,harvest_user.decrypt_password)

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
      harvest_sync.status = "new"
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
          #debugger
          prev_entry = HarvestEntry.find_by_harvest_id(harvest_entry.harvest_id)
          next if prev_entry or force_reload
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
        harvest_entry.status = new_status
        harvest_entry.redmine_user_id = redmine_user_id
        #hours_match = true if (prev_entry.hours == harvest_entry.hours)
        harvest_entry.save! unless prev_entry
        
        #use .inspect here...
        logger.info  "id: #{entry.xpath("id").text} | "
        logger.info  "hours: #{entry.xpath("hours").text} | "
        #logger.info  "hours_without_timer: #{entry.xpath("hours_without_timer").text} | "
        #logger.info  "spent_at: #{entry.xpath("spent_at").text} | "
        #logger.info  "user_id: #{entry.xpath("user_id").text} | "
        #logger.info  "client: #{entry.xpath("client").text} | "
        #logger.info  "project_id: #{entry.xpath("project_id").text} | "
        #logger.info  "project: #{entry.xpath("project").text} | "
        #logger.info  "task_id #{entry.xpath("task_id").text} | "
        #logger.info  "task: #{entry.xpath("task").text} | "
        logger.info  "notes: #{entry.xpath("notes").text} | "
      end #each
      
    rescue Exception => e
    	#TODO: implement error attr_accessor
      #flash[:error] = "#{l(:harvest_api_error)}: #{e}"
      error_string << "#{l(:harvest_api_error)}: #{e} "
    end 
    return error_string    
  end #fetch_entries

  def self.set_time_for_each_entry
  	

    harvest_entries = HarvestEntry.find(:all, :conditions => { :status => 'new' } )

  	harvest_entries.each do |entry|
  		redmine_issue_id = entry.notes.match /\d{4}/
  		next unless redmine_issue_id
      #TODO: do not use hard-coded redmine_user_id
      #next migration will have access to entry.redmine_user_id
      user = User.find(50)
  		issue = Issue.find(redmine_issue_id.to_s)
      project = issue.project
      activity = TimeEntryActivity.find_by_name('Development')

      te = TimeEntry.create(:spent_on => Date.strptime(entry.spent_at, '%Y-%m-%d'),
                          :hours    => entry.hours,
                          :issue    => issue,
                          :project  => project,
                          :user     => user,
                          :activity => activity,
                          :comments => entry.notes.mb_chars[0..255].strip.to_s) # Truncate comments to 255 charz
      
      te.save!
      entry.status = "synced"
      entry.save!
      
  	end

  end

  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end
  
end