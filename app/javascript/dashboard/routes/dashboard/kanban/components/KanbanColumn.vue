<template>
  <div 
    ref="columnElement"
    class="kanban-column"
    :style="columnStyle"
    @dragover.prevent
    @drop="handleDrop"
  >
    <div class="kanban-column__header">
      <div class="kanban-column__title">
        <span 
          v-if="stage.icon"
          class="kanban-column__icon"
        >
          <fluent-icon :icon="stage.icon" size="16" />
        </span>
        <h3>{{ stage.name }}</h3>
        <span class="kanban-column__count">{{ conversationCount }}</span>
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

<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
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
  filters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['drop']);
const { t } = useI18n();

// Local state
const localConversations = ref([...props.conversations]);
const columnElement = ref(null);

// Dynamic column styling with user-chosen colors
const columnStyle = computed(() => {
  const baseColor = props.stage.color || '#94A3B8';
  return {
    '--column-color': baseColor,
    '--column-header-bg': `${baseColor}10`, // 10% opacity
    '--column-border': `${baseColor}30`,     // 30% opacity
    '--column-accent': `${baseColor}20`,     // 20% opacity for subtle highlights
  };
});

// Enhanced conversation count with filter info
const conversationCount = computed(() => {
  const total = props.conversations.length;
  const filtered = localConversations.value.length;
  return total === filtered ? total : `${filtered}/${total}`;
});

// Watch for conversation changes
watch(
  () => props.conversations,
  (newVal) => {
    localConversations.value = [...newVal];
  },
  { deep: true }
);

// Drag and drop handlers
const handleDrop = (event) => {
  event.preventDefault();
  const conversationId = event.dataTransfer.getData('conversationId');
  const fromStage = event.dataTransfer.getData('fromStage');
  
  if (fromStage !== props.stage.key) {
    emit('drop', {
      conversationId: parseInt(conversationId, 10),
      fromStage,
      toStage: props.stage.key,
      position: calculateDropPosition(event),
    });
  }
};

const handleChange = (event) => {
  if (event.added) {
    const { element, newIndex } = event.added;
    const position = calculatePosition(newIndex);
    
    emit('drop', {
      conversationId: element.id,
      fromStage: null,
      toStage: props.stage.key,
      position,
    });
  } else if (event.moved) {
    const { element, newIndex } = event.moved;
    const position = calculatePosition(newIndex);
    
    emit('drop', {
      conversationId: element.id,
      fromStage: props.stage.key,
      toStage: props.stage.key,
      position,
    });
  }
};

// Position calculation helpers
const calculatePosition = (index) => {
  const position = {};
  
  if (index === 0 && localConversations.value.length > 1) {
    position.beforeId = localConversations.value[1].id;
  } else if (index === localConversations.value.length - 1 && index > 0) {
    position.afterId = localConversations.value[index - 1].id;
  } else if (index > 0 && index < localConversations.value.length - 1) {
    position.afterId = localConversations.value[index - 1].id;
    position.beforeId = localConversations.value[index + 1].id;
  }
  
  return position;
};

const calculateDropPosition = (event) => {
  const cards = columnElement.value?.querySelectorAll('.kanban-card') || [];
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
};
</script>

<style scoped lang="scss">
.kanban-column {
  display: flex;
  flex-direction: column;
  width: 360px;
  min-width: 360px;
  max-width: 360px;
  height: calc(100vh - 160px);
  background-color: var(--white);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--s-100);
  box-shadow: var(--shadow-medium);
  
  &__header {
    padding: var(--space-large);
    background: linear-gradient(135deg, var(--column-header-bg) 0%, var(--white) 100%);
    border-bottom: 1px solid var(--column-border);
    border-radius: var(--border-radius-normal) var(--border-radius-normal) 0 0;
    position: relative;
    
    &::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 3px;
      background: linear-gradient(90deg, var(--column-color) 0%, var(--column-color) 100%);
      border-radius: var(--border-radius-normal) var(--border-radius-normal) 0 0;
      box-shadow: 0 1px 3px var(--column-border);
    }
  }
  
  &__title {
    display: flex;
    align-items: center;
    gap: var(--space-small);
    
    h3 {
      flex: 1;
      margin: 0;
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
      letter-spacing: -0.01em;
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
    padding: 4px 10px;
    border-radius: var(--border-radius-full);
    background-color: var(--s-200);
    color: var(--s-800);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-bold);
    min-width: 28px;
    text-align: center;
  }
  
  &__body {
    flex: 1;
    overflow-y: auto;
    padding: var(--space-normal);
    background-color: var(--s-25);
  }
  
  &__empty {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 120px;
    border: 2px dashed var(--s-200);
    border-radius: var(--border-radius-normal);
    background-color: var(--white);
    margin: var(--space-small) 0;
    
    p {
      margin: 0;
      color: var(--s-500);
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
    }
  }
  
  &__cards {
    display: flex;
    flex-direction: column;
    gap: var(--space-normal);
    min-height: 120px;
    padding-bottom: var(--space-normal);
  }
}
</style>