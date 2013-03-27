class HarvestSettings < ActiveRecord::Base
  unloadable

  before_save :set_updated_at
  before_create :set_created_at
  before_create :set_default_status

  validates :redmine_issue, :numericality => { :only_integer => true, :greater_than => 0 }
  validate :any_present?
  validate :is_valid_redmine_issue?

  default_scope :conditions => [ 'status != "destroyed"' ]

  # scope :of, lambda { |userID|
  #   where :redmine_user_id => userID
  # } 

  def any_present?
    if %w(project task notes_string).all?{|attr| self[attr].blank?}
      errors.add :base, "Must include a project, task, or notes string!"
    end
  end

  def is_valid_redmine_issue?
    Issue.find(self.redmine_issue)
    rescue ActiveRecord::RecordNotFound
      errors.add :base, "Invalid Redmine issue!"
  end

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
