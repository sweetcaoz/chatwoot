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
      package_json_path = Rails.root.join('package.json')
      return false unless File.exist?(package_json_path)
      
      package_json = JSON.parse(File.read(package_json_path))
      dependencies = package_json['dependencies'] || {}
      dependencies.key?('vuedraggable')
    rescue StandardError => e
      Rails.logger.error "Kanban npm check failed: #{e.message}"
      false
    end

    def check_translations
      # Check if kanban translations file exists
      File.exist?(Rails.root.join('config/locales/kanban_en.yml')) ||
        I18n.exists?('en.KANBAN.TITLE')
    rescue StandardError => e
      Rails.logger.error "Kanban translations check failed: #{e.message}"
      false
    end
  end
end