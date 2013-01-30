namespace :redmine_harvest_smc do

  desc "Fetch remote Harvest entries and save them to our DB."
  task :fetch_entries, [:date] => :environment do |t, args|

    unless args[:date]
      #puts "You have to specify role name. Tip: 'rake redmine_harvest_smc:fetch_entries[date]'"
      #next
      puts "USING TODAY: #{Time.now.yday} "
      args[:date] = Time.now.yday
    end

    error_string = HarvestEntry.fetch_entries args[:date]
    puts "#{error_string}"

  end

  desc "Add time entries for each harvest entry."
  task :set_time_for_all_entries => :environment do 

    HarvestEntry.set_time_for_all_entries

  end

end