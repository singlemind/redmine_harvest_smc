class HarvestUser < ActiveRecord::Base
  unloadable
  
  validates_presence_of :harvest_username_crypt, :on => :create, :message => "can't be blank"
  validates_presence_of :harvest_password_crypt, :on => :create, :message => "can't be blank"
  
  before_save :encrypt_username
  before_save :encrypt_password
  before_save :set_redmine_user_id
  before_save :set_updated_at
  before_create :set_created_at
  
  def encrypt_username
    self.harvest_username_crypt = encrypt harvest_username_crypt
  end
  def encrypt_password
    self.harvest_password_crypt = encrypt harvest_password_crypt
  end
  
  def encrypt(string)
    #check to see if string is already encrypted.
    begin
      decrypt_test = decrypt(string)
    rescue
    end 

    unless decrypt_test.nil?  
      return string
    else 
      password = "ohso4Xoo"
      salt = "4EFAB921EEDABB547F6B1982C6E9E74AC4DF2AE10D5015FE0C16FFD0380E2E61"
      return EzCrypto::Key.encrypt_with_password password, salt, string
    end 
  end 

  def decrypt_username
    decrypt self.harvest_username_crypt
  end
  def decrypt_password 
    decrypt self.harvest_password_crypt
  end
  
  def decrypt (string)
    password = "ohso4Xoo"
    salt = "4EFAB921EEDABB547F6B1982C6E9E74AC4DF2AE10D5015FE0C16FFD0380E2E61"
    return EzCrypto::Key.decrypt_with_password password, salt, string
  end 
  
  def set_redmine_user_id
    self.redmine_user_id = User.current.id
  end
  
  def set_updated_at
    self.updated_at = Time.now
  end
  
  def set_created_at
    self.created_at = Time.now
  end
  
end