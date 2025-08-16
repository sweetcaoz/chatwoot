class CreateKanbanStages < ActiveRecord::Migration[7.1]
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