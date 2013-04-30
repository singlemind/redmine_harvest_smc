# redmine_harvest_smc

## Prerequisites: 
gem install ezcrypto --no-ri --no-rdoc
sudo apt-get install libxslt1-dev
gem install nokogiri --no-ri --no-rdoc 

---

[redmine.org/projects/redmine/wiki/Plugins](http://www.redmine.org/projects/redmine/wiki/Plugins
 "redmine.org")

## Installing a plugin:

1. Copy your plugin directory into #{RAILS_ROOT}/plugins (Redmine 2.x) or #{RAILS_ROOT}/vendor/plugins (Redmine 1.x). If you are downloading the plugin directly from GitHub, you can do so by changing into your plugin directory and issuing a command like git clone git://github.com/user_name/name_of_the_plugin.git.

2. If the plugin requires a migration, run the following command to upgrade your database (make a db backup before).

2.1. For Redmine 1.x:

	rake db:migrate_plugins RAILS_ENV=production

2.2. For Redmine 2.x:

	rake redmine:plugins:migrate RAILS_ENV=production

3. Restart Redmine

You should now be able to see the plugin list in Administration -> Plugins and configure the newly installed plugin (if the plugin requires to be configured).

## Uninstalling a plugin:

1. If the plugin required a migration, run the following command to downgrade your database (make a db backup before):

1.1. For Redmine 1.x:

	rake db:migrate:plugin NAME=plugin_name VERSION=0 RAILS_ENV=production

1.2. For Redmine 2.x:

	rake redmine:plugins:migrate NAME=plugin_name VERSION=0 RAILS_ENV=production

2. Remove your plugin from the plugins folder: #{RAILS_ROOT}/plugins (Redmine 2.x) or #{RAILS_ROOT}/vendor/plugins (Redmine 1.x)..

3. Restart Redmine
