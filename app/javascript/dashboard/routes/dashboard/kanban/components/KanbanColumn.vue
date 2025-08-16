<template>
  <div 
    class="kanban-column"
    :style="columnStyle"
    @dragover.prevent
    @drop="handleDrop"
  >
    <div class="kanban-column__header">
      <div class="kanban-column__title">
        <span 
          class="kanban-column__icon"
          v-if="stage.icon"
        >
          <fluent-icon :icon="stage.icon" size="16" />
        </span>
        <h3>{{ stage.name }}</h3>
        <span class="kanban-column__count">{{ conversations.length }}</span>
      </div>
    </div>
    
    <div class="kanban-column__body">
      <div 
        v-if="!conversations.length" 
        class="kanban-column__empty"
      >
        <p>{{ $t('KANBAN.COLUMN_EMPTY') }}</p>
      </div>
      
      <draggable
        v-else
        v-model="localConversations"
        :group="{ name: 'conversations' }"
        :animation="200"
        :disabled="isMoving"
        class="kanban-column__cards"
        @change="handleChange"
      >
        <template #item="{ element }">
          <KanbanCard
            :key="element.id"
            :conversation="element"
            :is-moving="isMoving"
          />
        </template>
      </draggable>
    </div>
  </div>
</template>

<script>
import draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';

export default {
  name: 'KanbanColumn',
  components: {
    draggable,
    KanbanCard,
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
    conversations: {
      type: Array,
      default: () => [],
    },
    isMoving: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      localConversations: [...this.conversations],
    };
  },
  computed: {
    columnStyle() {
      return {
        '--column-color': this.stage.color || '#94A3B8',
      };
    },
  },
  watch: {
    conversations(newVal) {
      this.localConversations = [...newVal];
    },
  },
  methods: {
    handleDrop(event) {
      event.preventDefault();
      const conversationId = event.dataTransfer.getData('conversationId');
      const fromStage = event.dataTransfer.getData('fromStage');
      
      if (fromStage !== this.stage.key) {
        this.$emit('drop', {
          conversationId: parseInt(conversationId, 10),
          fromStage,
          toStage: this.stage.key,
          position: this.calculateDropPosition(event),
        });
      }
    },
    
    handleChange(event) {
      if (event.added) {
        const { element, newIndex } = event.added;
        const position = this.calculatePosition(newIndex);
        
        this.$emit('drop', {
          conversationId: element.id,
          fromStage: null,
          toStage: this.stage.key,
          position,
        });
      } else if (event.moved) {
        const { element, newIndex } = event.moved;
        const position = this.calculatePosition(newIndex);
        
        this.$emit('drop', {
          conversationId: element.id,
          fromStage: this.stage.key,
          toStage: this.stage.key,
          position,
        });
      }
    },
    
    calculatePosition(index) {
      const position = {};
      
      if (index === 0 && this.localConversations.length > 1) {
        position.beforeId = this.localConversations[1].id;
      } else if (index === this.localConversations.length - 1 && index > 0) {
        position.afterId = this.localConversations[index - 1].id;
      } else if (index > 0 && index < this.localConversations.length - 1) {
        position.afterId = this.localConversations[index - 1].id;
        position.beforeId = this.localConversations[index + 1].id;
      }
      
      return position;
    },
    
    calculateDropPosition(event) {
      // Calculate position based on drop coordinates
      const cards = this.$el.querySelectorAll('.kanban-card');
      let afterId = null;
      let beforeId = null;
      
      cards.forEach((card, index) => {
        const rect = card.getBoundingClientRect();
        if (event.clientY < rect.top + rect.height / 2) {
          if (index === 0) {
            beforeId = parseInt(card.dataset.conversationId, 10);
          }
        } else {
          afterId = parseInt(card.dataset.conversationId, 10);
          if (cards[index + 1]) {
            beforeId = parseInt(cards[index + 1].dataset.conversationId, 10);
          }
        }
      });
      
      return { afterId, beforeId };
    },
  },
};
</script>

<style scoped lang="scss">
.kanban-column {
  display: flex;
  flex-direction: column;
  width: 320px;
  min-width: 320px;
  height: 100%;
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  box-shadow: var(--shadow-small);
  
  &__header {
    padding: var(--space-normal);
    border-bottom: 2px solid var(--column-color);
  }
  
  &__title {
    display: flex;
    align-items: center;
    gap: var(--space-small);
    
    h3 {
      flex: 1;
      margin: 0;
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
    }
  }
  
  &__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 24px;
    height: 24px;
    border-radius: var(--border-radius-small);
    background-color: var(--column-color);
    color: var(--white);
    opacity: 0.9;
  }
  
  &__count {
    padding: 2px 8px;
    border-radius: var(--border-radius-full);
    background-color: var(--s-100);
    color: var(--s-700);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
  }
  
  &__body {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-small);
  }
  
  &__empty {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100px;
    border: 2px dashed var(--s-200);
    border-radius: var(--border-radius-normal);
    
    p {
      margin: 0;
      color: var(--s-500);
      font-size: var(--font-size-small);
    }
  }
  
  &__cards {
    display: flex;
    flex-direction: column;
    gap: var(--space-small);
    min-height: 100px;
  }
}
</style>