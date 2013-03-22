class HarvestTask < ActiveRecord::Base
  unloadable
  validates_presence_of :task_name, :on => :create, :message => "can't be blank"

  scope :uniq_task, select("DISTINCT task_name")

end
