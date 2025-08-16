namespace :kanban do
  desc "Install Kanban feature (run migration and check dependencies)"
  task install: :environment do
    puts "Installing Kanban Feature..."
    puts "=" * 50
    
    # Check and run migration
    if ActiveRecord::Base.connection.table_exists?('kanban_stages')
      puts "✅ Migration already run - kanban_stages table exists"
    else
      puts "Running migration..."
      ActiveRecord::Migration.verbose = true
      
      # Create the migration inline
      migration_class = Class.new(ActiveRecord::Migration[7.1]) do
        def change
          create_table :kanban_stages do |t|
            t.references :account, null: false, foreign_key: { on_delete: :cascade }
            t.string :board_key, null: false, default: 'sales'
            t.string :key, null: false
            t.string :name, null: false
            t.string :color
            t.string :icon
            t.integer :position, null: false, default: 0
            t.boolean :active, null: false, default: true
            
            t.timestamps
          end

          add_index :kanban_stages, [:account_id, :board_key, :key], unique: true, name: 'index_kanban_stages_unique_key'
          add_index :kanban_stages, [:account_id, :board_key, :position], name: 'index_kanban_stages_position'
          add_index :kanban_stages, [:account_id, :board_key, :active], name: 'index_kanban_stages_active'
        end
      end
      
      migration_class.new.change
      puts "✅ Migration completed"
    end
    
    # Check NPM dependencies
    package_json = JSON.parse(File.read(Rails.root.join('package.json')))
    if package_json['dependencies']&.key?('vuedraggable')
      puts "✅ NPM package 'vuedraggable' is installed"
    else
      puts "⚠️  NPM package missing. Please run: npm install vuedraggable@next"
    end
    
    # Check translations
    if File.exist?(Rails.root.join('config/locales/kanban_en.yml'))
      puts "✅ Translations file exists"
    else
      puts "⚠️  Translations missing. Will be created when first account enables Kanban"
    end
    
    puts "=" * 50
    puts "Installation check complete!"
    puts ""
    puts "Next steps:"
    puts "1. Run 'npm install vuedraggable@next' if not already installed"
    puts "2. Restart your Rails server"
    puts "3. Go to Super Admin > Kanban Setup to enable for accounts"
  end
  
  desc "Enable Kanban for specific account"
  task :enable, [:account_id] => :environment do |_task, args|
    account = Account.find(args[:account_id])
    account.enable_features!(:kanban)
    
    if account.kanban_stages.empty?
      KanbanStage.create_default_stages_for_account(account)
    end
    
    puts "✅ Kanban enabled for account: #{account.name} (ID: #{account.id})"
  end
  
  desc "Disable Kanban for specific account"
  task :disable, [:account_id] => :environment do |_task, args|
    account = Account.find(args[:account_id])
    account.disable_features!(:kanban)
    
    puts "✅ Kanban disabled for account: #{account.name} (ID: #{account.id})"
  end
  
  desc "List accounts with Kanban enabled"
  task list_enabled: :environment do
    enabled_accounts = Account.with_feature_kanban
    
    if enabled_accounts.any?
      puts "Accounts with Kanban enabled:"
      enabled_accounts.each do |account|
        stages_count = account.kanban_stages.count
        puts "  - #{account.name} (ID: #{account.id}) - #{stages_count} stages"
      end
    else
      puts "No accounts have Kanban enabled"
    end
  end
end