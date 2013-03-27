namespace :redmine_harvest_smc do

  desc "Fetch remote Harvest entries for all users."
  task :fetch_entries_for_all_users, [:date] => :environment do |t, args|


    HarvestUser.all.each do |user|
      #puts "argz: #{user.redmine_user_id}, #{Time.now.yday}, #{Time.now.year}, true"
      error_string = HarvestEntry.validate_entries_for(user.redmine_user_id, Time.now.yday, Time.now.year, true)
      #puts "#{error_string}"
      
      #puts "ABOUT TO RECONCILE!"
      #HarvestEntry.reconcile user.redmine_user_id

    end

    puts "DONE!"

  end

  desc "Add time entries for each harvest entry."
  task :set_time_for_all_entries => :environment do 

    HarvestEntry.set_time_for_all_entries

  end

end