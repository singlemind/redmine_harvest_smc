# redmine_harvest_smc


### FEATURES: 

* Sync time entries made in Harvest with issues in Redmine
* Matches incoming Harvest entries against Redmine issue IDs from active projects
* Adds time entries to Redmine time tracking report 
* Attempts to match Harvest task name with Redmine time tracking entry description
* Redmine admin users can see and sync time for all users 
* Time column header cell shows sum total 
* Users can synchronize time using time report 1-click reconciliation of recent entries 
* Cron script for nightly (or more often) syncing 
* Admins can create an exclusion list where matching entries are ignored or associated with some blanket issue (e.g. break time could be added to a single master slip) 
* Time report page has filters (jQuery DataTables)
* Ensure matched issue IDs are from an active project
* Harvest admin users sync project and task names from Harvest for easier filtering on settings page


![OieXx6o.png](http://i.imgur.com/OieXx6o.png)


---

### PREREQUISITES:

Redmine 2.x 

	sudo apt-get install libxslt1-dev

	cd /path/to/redmine/plugins/redmine_harvest_smc/
	bundle install 

or install gems manually: 

	gem install ezcrypto --no-ri --no-rdoc
	gem install on_the_spot --no-ri --no-rdoc
	gem install nokogiri --no-ri --no-rdoc 


[redmine.org/projects/redmine/wiki/Plugins](http://www.redmine.org/projects/redmine/wiki/Plugins
 "redmine.org")

###  INSTALL

1. Copy your plugin directory into #{RAILS_ROOT}/plugins (Redmine 2.x) or #{RAILS_ROOT}/vendor/plugins (Redmine 1.x). If you are downloading the plugin directly from GitHub, you can do so by changing into your plugin directory and issuing a command like git clone git://github.com/user_name/name_of_the_plugin.git.

2. Update the password & salt used to encrypt Harvest usernames and passwords. Lines ~31,32,46, and 47 of app/models/harvest_user.rb

3. If the plugin requires a migration, run the following command to upgrade your database (make a db backup before).

3.1. For Redmine 2.x:

	rake redmine:plugins:migrate RAILS_ENV=production

4. Restart Redmine

You should now be able to see the plugin list in Administration -> Plugins and configure the newly installed plugin (if the plugin requires to be configured).

5. Enter your Harvest subdomain (e.g. http://subdomain.harvestapp.com/) on the settings page for this plugin

6. Enter your Harvest credentials on the “Harvest User” page linked in the top header menu in Harvest.

### UNINSTALL

1. If the plugin required a migration, run the following command to downgrade your database (make a db backup before):

1.1. For Redmine 2.x:

	rake redmine:plugins:migrate NAME=plugin_name VERSION=0 RAILS_ENV=production

2. Remove your plugin from the plugins folder: #{RAILS_ROOT}/plugins (Redmine 2.x) 

3. Restart Redmine



