class Api::V1::Accounts::Kanban::StagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :ensure_kanban_enabled
  before_action :fetch_stage, except: [:index, :create]
  before_action :check_authorization

  def index
    @stages = Current.account.kanban_stages
                     .for_board(params[:board_key] || KanbanStage::DEFAULT_BOARD_KEY)
                     .ordered
  end

  def show; end

  def create
    @stage = Current.account.kanban_stages.create!(permitted_params)
  end

  def update
    @stage.update!(permitted_params.except(:key))
  end

  def destroy
    if @stage.can_deactivate?
      @stage.update!(active: false)
      head :ok
    else
      render json: { error: 'Cannot deactivate the only active stage' }, status: :unprocessable_entity
    end
  end

  def reorder
    stages = Current.account.kanban_stages
                    .for_board(@stage.board_key)
                    .where(id: params[:stage_ids])
    
    stages.each_with_index do |stage, index|
      stage.update!(position: index)
    end
    
    head :ok
  end

  private

  def ensure_kanban_enabled
    unless KanbanDependencyService.kanban_available_for_account?(Current.account)
      render json: { 
        error: 'Kanban feature is not enabled for this account',
        dependencies_met: KanbanDependencyService.dependencies_met?,
        feature_enabled: Current.account.feature_kanban?
      }, status: :forbidden
    end
  end

  def fetch_stage
    @stage = Current.account.kanban_stages.find(params[:id])
  end

  def permitted_params
    params.require(:stage).permit(:board_key, :key, :name, :color, :icon, :position, :active)
  end
end