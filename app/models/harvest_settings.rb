class HarvestSettings < ActiveRecord::Base
  unloadable

  before_save :set_updated_at
  before_create :set_created_at
  before_create :set_default_status

  validates :notes_string, :presence => true
  validates :redmine_issue, :presence => true

  default_scope :conditions => [ 'status != "destroyed"' ]

  scope :of, lambda { |userID|
    where :redmine_user_id => userID
  } 

  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end

  def set_default_status 
    self.status = 'created'
  end

end
