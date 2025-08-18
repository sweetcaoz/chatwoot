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
    @board_key = params[:board_key] || KanbanStage::DEFAULT_BOARD_KEY
    
    # Multi-tenant safety: ensure conversation belongs to current account
    @conversation = Current.account.conversations
                           .includes(:contact, :inbox, :assignee, :team, :labels)
                           .find(params[:conversation_id])
    
    # Multi-tenant safety: ensure stage belongs to current account and board
    target_stage = Current.account.kanban_stages
                          .active
                          .for_board(@board_key)
                          .find_by(key: params[:stage_key])
    
    unless target_stage
      available_stages = Current.account.kanban_stages.active.for_board(@board_key).pluck(:key)
      Rails.logger.error("[KANBAN] Stage '#{params[:stage_key]}' not found for account #{Current.account.id}, board '#{@board_key}'. Available: #{available_stages}")
      render json: { 
        error: "Stage '#{params[:stage_key]}' not found",
        available_stages: available_stages 
      }, status: :not_found
      return
    end
    
    ActiveRecord::Base.transaction do
      update_conversation_stage
      update_conversation_position
    end
    
    broadcast_kanban_update
    
    # Reload conversation to ensure we have the latest data
    @conversation.reload
    
    # Return updated conversation data for smooth frontend sync
    render json: { 
      status: 'success', 
      message: 'Conversation moved successfully',
      conversation: format_single_conversation(@conversation)
    }
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("[KANBAN] Multi-tenant access violation or record not found: #{e.message}")
    render json: { error: 'Conversation not found or access denied' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[KANBAN] Unexpected error: #{e.class} - #{e.message}")
    render json: { error: 'Failed to move conversation' }, status: :internal_server_error
  end

  private

  def check_authorization
    authorize(Current.account, :kanban_board?)
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
           .includes(:contact, :inbox, :assignee, :team, :labels)
           .where("custom_attributes ->> 'kanban_stage' = ?", stage_key)
           .select("conversations.*, 
                    COALESCE((custom_attributes ->> 'kanban_position')::float, conversations.id * 1000.0) as kanban_position")
           .order(Arel.sql('kanban_position ASC'))
           .limit(50)
  end

  def format_conversations(conversations)
    conversations.map { |conversation| format_single_conversation(conversation) }
      .sort_by { |conv| [-conv[:unread_count], conv[:kanban_position]] }
  end

  def format_single_conversation(conversation)
    # Calculate unread count using the model method
    unread_count = conversation.unread_incoming_messages.count
    
    {
      id: conversation.id,
      display_id: conversation.display_id,
      contact: conversation.contact.attributes.slice('id', 'name', 'email', 'phone_number', 'avatar_url'),
      inbox: conversation.inbox.attributes.slice('id', 'name', 'channel_type'),
      assignee: conversation.assignee&.attributes&.slice('id', 'name', 'available_name', 'avatar_url'),
      team: conversation.team&.attributes&.slice('id', 'name'),
      status: conversation.status,
      priority: conversation.priority,
      labels: conversation.labels,
      unread_count: unread_count,
      kanban_position: conversation.respond_to?(:kanban_position) ? conversation.kanban_position : conversation.custom_attributes['kanban_position'],
      last_activity_at: conversation.last_activity_at,
      created_at: conversation.created_at,
      custom_attributes: conversation.custom_attributes,
      last_message: conversation.last_incoming_message ? {
        content: conversation.last_incoming_message.content
      } : nil
    }
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