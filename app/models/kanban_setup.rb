# Dummy model for Administrate navigation
# KanbanSetup is not a real ActiveRecord model, but Administrate requires
# a model class to exist for dashboard navigation to work properly
class KanbanSetup
  include ActiveModel::Model
  
  # Administrate expects these methods
  def self.all
    []
  end
  
  def self.find(_id)
    new
  end
  
  def self.count
    0
  end
  
  def persisted?
    false
  end
  
  def id
    nil
  end
  
  def to_param
    nil
  end
end