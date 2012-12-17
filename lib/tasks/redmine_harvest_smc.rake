namespace :redmine_harvest_smc do


  desc "Fetch remote Harvest entries and save them to our DB."
  task :fetch_entries, [:date] => :environment do |t, args|

    unless args[:date]
      puts "You have to specify role name. Tip: 'rake redmine_harvest_smc:fetch_entries[date]'"
      next
    end

    HarvestEntry.fetch_entries args[:date]

  end


  

end
