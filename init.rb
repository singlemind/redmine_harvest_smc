require 'redmine'
require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require 'ezcrypto'
require 'harvest_client'

Redmine::Plugin.register :redmine_harvest_smc do
  name 'Redmine Harvest SMC plugin'
  author 'Edward Sharp'
  description 'A plugin to sync Harvest entries with Redmine issues.'
  version '0.0.1'
  url 'http://singlemind.co'
  author_url 'http://edwardsharp.net'
  
  requires_redmine :version_or_higher => '1.3.0'
  
  settings :default => {
    :foo => false
  }, :partial => 'harvest_smc/settings'
  
  Redmine::AccessControl.map do |map|
    map.project_module :redmine_harvest_smc do |map|
      #map.permission :harvest, {:harvest_entry => [:index, :fetch_entries, :harvest_user]}
      map.permission :harvest, {:harvest_entry => :index, :harvest_entry => :fetch_entries, :harvest_entry => :harvest_user}, :require => :loggedin

      #ex.
      #map.permission :edit_checklists, {:issue_checklist => :delete, :issue_checklist => :done}
      #TODO: yank example.
    end 
  end 
  
end

