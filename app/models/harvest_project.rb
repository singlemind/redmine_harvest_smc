class HarvestProject < ActiveRecord::Base
  unloadable
  validates_presence_of :project_name, :on => :create, :message => "can't be blank"

	scope :uniq_project, select("DISTINCT project_name")

end
