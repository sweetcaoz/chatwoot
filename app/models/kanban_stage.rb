class KanbanStage < ApplicationRecord
  belongs_to :account

  validates :board_key, presence: true
  validates :key, presence: true, uniqueness: { scope: [:account_id, :board_key] }
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validate :key_immutable, on: :update

  scope :active, -> { where(active: true) }
  scope :for_board, ->(board_key) { where(board_key: board_key) }
  scope :ordered, -> { order(position: :asc) }

  before_validation :set_default_position, on: :create
  after_create :assign_conversations_to_default_stage
  after_update :handle_deactivation, if: :saved_change_to_active?

  DEFAULT_BOARD_KEY = 'sales'.freeze
  DEFAULT_STAGES = [
    { key: 'new', name: 'New', color: '#0EA5E9', icon: 'sparkle', position: 0 },
    { key: 'qualified', name: 'Qualified', color: '#8B5CF6', icon: 'person-check', position: 1 },
    { key: 'proposal', name: 'Proposal', color: '#F59E0B', icon: 'document', position: 2 },
    { key: 'negotiation', name: 'Negotiation', color: '#10B981', icon: 'chat-multiple', position: 3 },
    { key: 'closed', name: 'Closed', color: '#6B7280', icon: 'checkmark-circle', position: 4 }
  ].freeze

  def self.create_default_stages_for_account(account)
    DEFAULT_STAGES.each do |stage_attrs|
      account.kanban_stages.create!(
        stage_attrs.merge(board_key: DEFAULT_BOARD_KEY)
      )
    end
  end

  def self.default_stage_for_board(account, board_key = DEFAULT_BOARD_KEY)
    account.kanban_stages
           .active
           .for_board(board_key)
           .ordered
           .first
  end

  def conversations
    account.conversations.where("custom_attributes ->> 'kanban_stage' = ?", key)
  end

  def conversations_count
    account.conversations.where("custom_attributes ->> 'kanban_stage' = ?", key).count
  end

  def can_deactivate?
    return true if conversations_count.zero?
    
    other_active_stages = account.kanban_stages
                                  .active
                                  .for_board(board_key)
                                  .where.not(id: id)
    other_active_stages.exists?
  end

  private

  def key_immutable
    errors.add(:key, 'cannot be changed') if key_changed? && persisted?
  end

  def set_default_position
    return if position.present? && position > 0

    max_position = account.kanban_stages
                          .for_board(board_key)
                          .maximum(:position) || -1
    self.position = max_position + 1
  end

  def assign_conversations_to_default_stage
    return unless account.kanban_stages.for_board(board_key).count == 1

    account.conversations.find_each do |conversation|
      conversation.custom_attributes['kanban_stage'] = key
      conversation.custom_attributes['kanban_position'] = conversation.id * 1000.0
      conversation.save!
    end
  end

  def handle_deactivation
    return if active?
    
    migrate_conversations_to_default_stage
  end

  def migrate_conversations_to_default_stage
    default_stage = self.class.default_stage_for_board(account, board_key)
    return unless default_stage && default_stage != self

    conversations.find_each do |conversation|
      conversation.custom_attributes['kanban_stage'] = default_stage.key
      conversation.save!
    end
  end
end