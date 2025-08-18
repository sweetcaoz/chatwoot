class SuperAdmin::KanbanSetupController < SuperAdmin::ApplicationController
  before_action :set_account, only: [:enable_for_account, :disable_for_account]
  
  def index
    @dependency_status = KanbanDependencyService.check_all_dependencies
    @enabled_accounts_count = Account.where("feature_flags & ? > 0", Account.flag_mapping[:feature_kanban]).count
    @total_accounts = Account.count
  end

  def install_dependencies
    begin
      # Run migration using proper Rails migration
      if params[:run_migration] == 'true'
        # Check if migration needs to be run
        unless ActiveRecord::Base.connection.table_exists?('kanban_stages')
          # Run pending migrations that include kanban
          Rails.application.load_tasks
          Rake::Task['db:migrate'].invoke
          flash[:notice] = 'Migration completed successfully'
        else
          flash[:notice] = 'Migration already completed'
        end
      end

      # No NPM packages needed for HTML5 implementation
      if params[:npm_command]
        flash[:notice] = 'No NPM packages required - using native HTML5 drag-and-drop'
      end

      # Add translations
      if params[:add_translations] == 'true'
        add_kanban_translations
        flash[:notice] = 'Translations added successfully'
      end

      # Create default stages for all accounts (optional)
      if params[:create_default_stages] == 'true'
        create_default_stages_for_all_accounts
        flash[:notice] = 'Default stages created for all accounts'
      end

      redirect_to super_admin_kanban_setup_index_path
    rescue StandardError => e
      flash[:error] = "Installation failed: #{e.message}"
      redirect_to super_admin_kanban_setup_index_path
    end
  end

  def enable_for_account
    @account.enable_features!(:kanban)
    
    # Create default stages when enabling for the first time
    if @account.kanban_stages.empty?
      KanbanStage.create_default_stages_for_account(@account)
    end
    
    flash[:notice] = "Kanban enabled for #{@account.name}"
    redirect_to super_admin_kanban_setup_index_path
  rescue StandardError => e
    flash[:error] = "Failed to enable Kanban: #{e.message}"
    redirect_to super_admin_kanban_setup_index_path
  end

  def disable_for_account
    @account.disable_features!(:kanban)
    flash[:notice] = "Kanban disabled for #{@account.name}"
    redirect_to super_admin_kanban_setup_index_path
  rescue StandardError => e
    flash[:error] = "Failed to disable Kanban: #{e.message}"
    redirect_to super_admin_kanban_setup_index_path
  end

  def bulk_enable
    account_ids = bulk_enable_params[:account_ids] || []
    return redirect_to(super_admin_kanban_setup_index_path, alert: 'No accounts selected') if account_ids.empty?
    
    enabled_count = 0
    Account.where(id: account_ids).find_each do |account|
      account.enable_features!(:kanban)
      KanbanStage.create_default_stages_for_account(account) if account.kanban_stages.empty?
      enabled_count += 1
    end
    
    flash[:notice] = "Kanban enabled for #{enabled_count} accounts"
    redirect_to super_admin_kanban_setup_index_path
  rescue StandardError => e
    flash[:error] = "Bulk enable failed: #{e.message}"
    redirect_to super_admin_kanban_setup_index_path
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Account not found'
    redirect_to super_admin_kanban_setup_index_path
  end

  def bulk_enable_params
    params.permit(account_ids: [])
  end


  def add_kanban_translations
    # This would add translations to the appropriate locale files
    # For now, we'll create a YAML file that can be merged
    translations = {
      'en' => {
        'SIDEBAR' => {
          'KANBAN' => 'Kanban Board'
        },
        'KANBAN' => {
          'TITLE' => 'Kanban Board',
          'SUBTITLE' => 'Manage conversations in a visual pipeline',
          'LOADING' => 'Loading board...',
          'NO_STAGES' => 'No Stages Configured',
          'NO_STAGES_DESCRIPTION' => 'Configure stages to start using the Kanban board',
          'CREATE_STAGES' => 'Configure Stages',
          'MANAGE_STAGES' => 'Manage Stages',
          'COLUMN_EMPTY' => 'No conversations in this stage',
          'NO_SUBJECT' => 'No subject',
          'MOVE_ERROR' => 'Failed to move conversation',
          'STAGE_MANAGER' => {
            'TITLE' => 'Manage Kanban Stages',
            'ADD_STAGE' => 'Add Stage',
            'EDIT_STAGE' => 'Edit Stage',
            'CREATE_STAGE' => 'Create Stage',
            'KEY' => 'Key',
            'CONVERSATIONS' => 'conversations',
            'STAGE_NAME' => 'Stage Name',
            'STAGE_NAME_PLACEHOLDER' => 'e.g., New, In Progress, Done',
            'STAGE_KEY' => 'Stage Key (cannot be changed)',
            'STAGE_KEY_PLACEHOLDER' => 'e.g., new, in_progress, done',
            'STAGE_COLOR' => 'Stage Color',
            'STAGE_ICON' => 'Stage Icon',
            'STAGE_ICON_PLACEHOLDER' => 'e.g., flag, check-circle',
            'DELETE_TITLE' => 'Delete Stage',
            'DELETE_MESSAGE' => "Are you sure you want to delete the stage '%{name}'? It has %{count} conversations that will be moved to the default stage.",
            'NAME_REQUIRED' => 'Stage name is required',
            'KEY_REQUIRED' => 'Stage key is required',
            'REORDER_SUCCESS' => 'Stages reordered successfully',
            'REORDER_ERROR' => 'Failed to reorder stages',
            'UPDATE_SUCCESS' => 'Stage updated successfully',
            'CREATE_SUCCESS' => 'Stage created successfully',
            'SAVE_ERROR' => 'Failed to save stage',
            'STATUS_UPDATED' => 'Stage status updated',
            'STATUS_ERROR' => 'Failed to update stage status',
            'DELETE_SUCCESS' => 'Stage deleted successfully',
            'DELETE_ERROR' => 'Failed to delete stage'
          }
        }
      }
    }
    
    # Write to a temporary file or merge with existing translations
    File.write(Rails.root.join('config/locales/kanban_en.yml'), translations.to_yaml)
  end

  def create_default_stages_for_all_accounts
    Account.find_each do |account|
      next unless account.kanban_stages.empty?
      KanbanStage.create_default_stages_for_account(account)
    end
  end
end