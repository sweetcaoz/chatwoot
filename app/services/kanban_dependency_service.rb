class KanbanDependencyService
  class << self
    def dependencies_met?
      status = check_all_dependencies
      status[:migration] && status[:npm_packages] && status[:translations]
    end

    def check_all_dependencies
      {
        migration: check_migration,
        npm_packages: check_npm_packages,
        translations: check_translations,
        can_enable: check_migration && check_npm_packages && check_translations
      }
    end

    def kanban_available_for_account?(account)
      # Check if dependencies are met
      return false unless dependencies_met?
      
      # Check if account has feature enabled
      account.feature_kanban?
    end

    private

    def check_migration
      ActiveRecord::Base.connection.table_exists?('kanban_stages')
    rescue StandardError => e
      Rails.logger.error "Kanban migration check failed: #{e.message}"
      false
    end

    def check_npm_packages
      # HTML5 drag-and-drop requires no external packages
      # Always return true since drag functionality is built into browsers
      true
    rescue StandardError => e
      Rails.logger.error "Kanban npm check failed: #{e.message}"
      false
    end

    def check_translations
      # Check if frontend kanban translations file exists
      frontend_translation_path = Rails.root.join('app/javascript/dashboard/i18n/locale/en/kanban.json')
      File.exist?(frontend_translation_path)
    rescue StandardError => e
      Rails.logger.error "Kanban translations check failed: #{e.message}"
      false
    end
  end
end