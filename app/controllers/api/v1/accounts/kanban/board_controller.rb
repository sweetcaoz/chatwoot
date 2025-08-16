class Api::V1::Accounts::Kanban::BoardController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :debug_context
  before_action :ensure_kanban_enabled
  before_action :check_authorization

  def index
    @board_key = params[:board_key] || KanbanStage::DEFAULT_BOARD_KEY
    @stages = fetch_stages
    @conversations_by_stage = fetch_conversations_by_stage
  end

  def move
    @conversation = Current.account.conversations.find(params[:conversation_id])
    
    ActiveRecord::Base.transaction do
      update_conversation_stage
      update_conversation_position
    end
    
    broadcast_kanban_update
    head :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'Conversation not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: 'Failed to move conversation' }, status: :internal_server_error
  end

  private

  def check_authorization
    authorize(Current.account)
  end

  def debug_context
    Rails.logger.info("[KANBAN] user_id=#{current_user&.id} params_account_id=#{params[:account_id]} "\
                      "Current.account=#{Current.account&.id} Current.account_user=#{Current.account_user&.id}")
  end

  def pundit_user
    {
      user: current_user,
      account: Current.account,
      account_user: Current.account_user
    }
  end

  def ensure_kanban_enabled
    unless KanbanDependencyService.kanban_available_for_account?(Current.account)
      render json: { 
        error: 'Kanban feature is not enabled for this account',
        dependencies_met: KanbanDependencyService.dependencies_met?,
        feature_enabled: Current.account.feature_kanban?
      }, status: :forbidden
    end
  end

  def fetch_stages
    Current.account.kanban_stages
           .active
           .for_board(@board_key)
           .ordered
  end

  def fetch_conversations_by_stage
    conversations_data = {}
    
    @stages.each do |stage|
      conversations = fetch_stage_conversations(stage.key)
      conversations_data[stage.key] = format_conversations(conversations)
    end
    
    conversations_data
  end

  def fetch_stage_conversations(stage_key)
    Current.account.conversations
           .includes(:contact, :inbox, :assignee, :team, :labels, :taggings)
           .where("custom_attributes ->> 'kanban_stage' = ?", stage_key)
           .select("conversations.*, 
                    COALESCE((custom_attributes ->> 'kanban_position')::float, conversations.id * 1000.0) as kanban_position,
                    (conversations.unread_incoming_messages_count > 0) as has_unread")
           .order(Arel.sql('has_unread DESC, kanban_position ASC'))
           .limit(50)
  end

  def format_conversations(conversations)
    conversations.map do |conversation|
      {
        id: conversation.id,
        display_id: conversation.display_id,
        contact: conversation.contact.slice(:id, :name, :email, :phone_number, :avatar_url),
        inbox: conversation.inbox.slice(:id, :name, :channel_type),
        assignee: conversation.assignee&.slice(:id, :name, :available_name, :avatar_url),
        team: conversation.team&.slice(:id, :name),
        status: conversation.status,
        priority: conversation.priority,
        labels: conversation.label_list,
        unread_count: conversation.unread_incoming_messages_count,
        kanban_position: conversation.kanban_position,
        last_activity_at: conversation.last_activity_at,
        created_at: conversation.created_at
      }
    end
  end

  def update_conversation_stage
    stage = Current.account.kanban_stages
                   .active
                   .for_board(@board_key)
                   .find_by!(key: params[:stage_key])
    
    @conversation.custom_attributes['kanban_stage'] = stage.key
    @conversation.save!
  end

  def update_conversation_position
    position = calculate_new_position(params[:position_params])
    @conversation.custom_attributes['kanban_position'] = position
    @conversation.save!
  end

  def calculate_new_position(position_params)
    return position_params[:absolute_position].to_f if position_params&.dig(:absolute_position)
    return Time.now.to_f * 1000 unless position_params.is_a?(Hash)
    
    begin
      if position_params[:after_id] && position_params[:before_id]
        after_conversation = Current.account.conversations.find(position_params[:after_id])
        before_conversation = Current.account.conversations.find(position_params[:before_id])
        
        after_pos = (after_conversation.custom_attributes['kanban_position'] || 0).to_f
        before_pos = (before_conversation.custom_attributes['kanban_position'] || 0).to_f
        
        (after_pos + before_pos) / 2.0
      elsif position_params[:after_id]
        after_conversation = Current.account.conversations.find(position_params[:after_id])
        after_pos = (after_conversation.custom_attributes['kanban_position'] || 0).to_f
        after_pos + 1000.0
      elsif position_params[:before_id]
        before_conversation = Current.account.conversations.find(position_params[:before_id])
        before_pos = (before_conversation.custom_attributes['kanban_position'] || 0).to_f
        before_pos - 1000.0
      else
        Time.now.to_f * 1000
      end
    rescue ActiveRecord::RecordNotFound
      # Fallback if referenced conversations don't exist
      Time.now.to_f * 1000
    end
  end

  def broadcast_kanban_update
    ActionCable.server.broadcast(
      "kanban_#{Current.account.id}_#{@board_key}",
      {
        event: 'conversation_moved',
        conversation_id: @conversation.id,
        stage_key: @conversation.custom_attributes['kanban_stage'],
        position: @conversation.custom_attributes['kanban_position']
      }
    )
  end

  # Note: We're using custom_attributes directly on conversations
  # No need to create CustomAttributeDefinition records since
  # conversations.custom_attributes is a JSONB column that accepts any keys
end