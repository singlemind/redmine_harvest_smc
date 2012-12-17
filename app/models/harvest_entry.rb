class HarvestEntry < ActiveRecord::Base
  unloadable
  
  attr_accessor :errors

  before_save :set_updated_at
  before_create :set_created_at
  
  def fetch_entries(day_of_the_year = Time.now.yday, year = Time.now.year)
  	force_reload = false
  	force_sync = false
  	force_timer = false
  	self.errors = ""

    harvest_user = HarvestUser.find_by_redmine_user_id(User.current.id)
    if (harvest_user.nil?)
      #flash[:error] = "#{l(:no_user_set)}"
      self.errors << = "#{l(:no_user_set)} "
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
        
        #hours_match = true if (prev_entry.hours == harvest_entry.hours)
        harvest_entry.save! unless prev_entry
        
        #use .inspect here...
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
    	#TODO: implement error attr_accessor
      #flash[:error] = "#{l(:harvest_api_error)}: #{e}"
      self.errors << = "#{l(:harvest_api_error)}: #{e} "
    end 
    
  end #fetch_entries

  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end
  
end