require 'administrate/base_dashboard'

class KanbanSetupDashboard < Administrate::BaseDashboard
  # This is a placeholder dashboard for the Kanban Setup feature
  # It doesn't represent a real model but is needed for navigation
  
  ATTRIBUTE_TYPES = {}.freeze
  COLLECTION_ATTRIBUTES = [].freeze
  SHOW_PAGE_ATTRIBUTES = [].freeze
  FORM_ATTRIBUTES = [].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(resource)
    'Kanban Setup'
  end
end