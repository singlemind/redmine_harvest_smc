# redmine_harvest_smc

This is a Redmine plugin used to sync time entries made in Harvest with issues in Redmine. It scans the notes field of incoming Harvest entries for a 2-5 digit number which would correspond to a Redmine issue ID. When an issue is found it adds time to Redmine accordingly. There's also a feature to set custom filters based on some combination the name of the project, task, or a string occurrence (regex) in the notes. Entries from Harvest are displayed in the Redmine UI using the [jQuery DataTables](http://www.datatables.net/ "jQuery DataTables") plugin which offers filtering, paging, and some other snazzy UI elements. The `lib/tasks/redmine_harvest_smc_rake.sh` file can be put into the system crontab to establish regular sync jobs for all the registered users.

Here’s a quick tutorial: 

Once you log in you’ll notice a couple extra links in the header of Redmine-- go ahead a click the “Harvest User” link and enter your Harvest login credentials. 

![Gm9nF9b.png](http://i.imgur.com/Gm9nF9b.png)

So now you can click on the “Harvest” link and begin syncing Harvest Entries. Select a “from” and “to” dates and click “SYNC” button and you’re off to the races. When checked, the “FORCE” option will first drop all the associated time entries for the timeframe selected and then import fresh from Harvest-- it’s enabled by default. You probably will never need to change this. Redmine admin users get a checkbox to sync entries for all users.

![JJDrvw5.png](http://i.imgur.com/JJDrvw5.png)

This is the main view built with jQuery DataTables that includes all synced Harvest entries. Issues that don’t have an associated issue will be marked as “problem”. To resolve simply enter an issue ID in the Harvest notes-- use the ⃔  link to go to the timesheet on harvestapp.com for that day. 

![OieXx6o.png](http://i.imgur.com/OieXx6o.png)

Here are some basic filters used for filtering data in the Harvest entry table.

![txyRpjO.png](http://i.imgur.com/txyRpjO.png)

As well as some other useful controls for changing how the table looks. 

![FBxUwbm.png](http://i.imgur.com/FBxUwbm.png)

![CPyenBb.png](http://i.imgur.com/CPyenBb.png)


---

### Prerequisites: 

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

### Installing a plugin:

1. Copy your plugin directory into #{RAILS_ROOT}/plugins (Redmine 2.x) or #{RAILS_ROOT}/vendor/plugins (Redmine 1.x). If you are downloading the plugin directly from GitHub, you can do so by changing into your plugin directory and issuing a command like git clone git://github.com/user_name/name_of_the_plugin.git.

2. If the plugin requires a migration, run the following command to upgrade your database (make a db backup before).

2.1. For Redmine 2.x:

	rake redmine:plugins:migrate RAILS_ENV=production

3. Restart Redmine

You should now be able to see the plugin list in Administration -> Plugins and configure the newly installed plugin (if the plugin requires to be configured).

### Uninstalling a plugin:

1. If the plugin required a migration, run the following command to downgrade your database (make a db backup before):

1.1. For Redmine 2.x:

	rake redmine:plugins:migrate NAME=plugin_name VERSION=0 RAILS_ENV=production

2. Remove your plugin from the plugins folder: #{RAILS_ROOT}/plugins (Redmine 2.x) 

3. Restart Redmine


