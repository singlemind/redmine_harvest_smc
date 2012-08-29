class HarvestSync < ActiveRecord::Base
  unloadable
  
  before_save :set_updated_at
  before_create :set_created_at
  
  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end
  
  #TODO build method to iterate thru HarvestEntries and add times corresponding issues. 
  
end