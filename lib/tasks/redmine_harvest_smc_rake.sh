#!/usr/bin/env bash

# load rvm ruby
source /home/redmine2/.rvm/environments/ruby-1.9.3-p392

rake redmine_harvest_smc:fetch_entries_for_all_users
