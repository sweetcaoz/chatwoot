<template>
  <div 
    ref="columnElement"
    class="kanban-column"
    :class="{ 'kanban-column--moving': isMoving }"
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
      
      <div 
        v-else
        class="kanban-column__cards"
        :class="{ 'kanban-column__cards--drag-over': isDraggedOver }"
        @dragover.prevent="handleDragOver"
        @dragenter.prevent="handleDragEnter"
        @dragleave="handleDragLeave"
        @drop="handleColumnDrop"
      >
        <template v-for="(conversation, index) in localConversations" :key="conversation.id">
          <!-- Drop indicator -->
          <div 
            v-if="dragOverIndex === index"
            class="kanban-column__drop-indicator"
          ></div>
          
          <div
            :draggable="!isMoving"
            class="kanban-conversation-item"
            :class="{ 'dragging': conversation.isDragging }"
            @dragstart="handleConversationDragStart($event, conversation, index)"
            @dragend="handleConversationDragEnd($event, conversation)"
          >
            <KanbanCard
              :conversation="conversation"
              :is-moving="isMoving"
            />
          </div>
        </template>
        
        <!-- Final drop indicator -->
        <div 
          v-if="dragOverIndex === localConversations.length"
          class="kanban-column__drop-indicator"
        ></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
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
const columnElement = ref(null);
const dragOverIndex = ref(-1);
const isDraggedOver = ref(false);

// Reactive local conversations for immediate UI updates
const localConversations = ref([...props.conversations]);

// Watch for props changes to sync local state
watch(() => props.conversations, (newConversations) => {
  localConversations.value = [...newConversations];
}, { deep: true });

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
  return props.conversations.length;
});

// HTML5 Drag and Drop Handlers
const handleDragEnter = (event) => {
  event.preventDefault();
  isDraggedOver.value = true;
};

const handleDragLeave = (event) => {
  // Only reset if leaving the column entirely
  if (!event.currentTarget.contains(event.relatedTarget)) {
    isDraggedOver.value = false;
    dragOverIndex.value = -1;
  }
};

const handleDragOver = (event) => {
  event.preventDefault();
  isDraggedOver.value = true;
  
  // Calculate insertion index based on mouse position
  const cards = Array.from(event.currentTarget.querySelectorAll('.kanban-conversation-item'));
  let insertIndex = cards.length;
  
  for (let i = 0; i < cards.length; i++) {
    const card = cards[i];
    const rect = card.getBoundingClientRect();
    const cardMiddle = rect.top + rect.height / 2;
    
    if (event.clientY < cardMiddle) {
      insertIndex = i;
      break;
    }
  }
  
  dragOverIndex.value = insertIndex;
};

const handleColumnDrop = (event) => {
  event.preventDefault();
  isDraggedOver.value = false;
  
  const conversationId = parseInt(event.dataTransfer.getData('conversationId'), 10);
  const fromStage = event.dataTransfer.getData('fromStage');
  const fromIndex = parseInt(event.dataTransfer.getData('fromIndex'), 10);
  
  if (!conversationId) return;
  
  const targetIndex = dragOverIndex.value;
  dragOverIndex.value = -1;
  
  // Calculate position for API
  const position = calculatePositionForAPI(targetIndex);
  
  emit('drop', {
    conversationId,
    fromStage,
    toStage: props.stage.key,
    position,
  });
};

const handleConversationDragStart = (event, conversation, index) => {
  if (props.isMoving) {
    event.preventDefault();
    return;
  }
  
  // Set drag data
  event.dataTransfer.setData('conversationId', conversation.id.toString());
  event.dataTransfer.setData('fromStage', props.stage.key);
  event.dataTransfer.setData('fromIndex', index.toString());
  event.dataTransfer.effectAllowed = 'move';
  
  // Create custom drag image (reuse existing KanbanCard drag styling)
  const dragImage = event.target.cloneNode(true);
  dragImage.style.cssText = `
    position: absolute;
    top: -1000px;
    left: -1000px;
    width: ${event.target.offsetWidth}px;
    height: ${event.target.offsetHeight}px;
    transform: scale(0.95) rotate(3deg);
    opacity: 0.9;
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
    border-radius: 12px;
    pointer-events: none;
    z-index: 9999;
  `;
  
  document.body.appendChild(dragImage);
  
  const rect = event.target.getBoundingClientRect();
  const offsetX = event.clientX - rect.left;
  const offsetY = event.clientY - rect.top;
  event.dataTransfer.setDragImage(dragImage, offsetX, offsetY);
  
  // Mark conversation as dragging for visual feedback
  conversation.isDragging = true;
  
  // Clean up drag image
  setTimeout(() => {
    if (dragImage.parentNode) {
      document.body.removeChild(dragImage);
    }
  }, 0);
};

const handleConversationDragEnd = (event, conversation) => {
  conversation.isDragging = false;
  isDraggedOver.value = false;
  dragOverIndex.value = -1;
};

// Position calculation helpers
const calculatePositionForAPI = (targetIndex) => {
  const position = {};
  const conversations = localConversations.value;
  
  if (targetIndex === 0 && conversations.length > 0) {
    // Insert at beginning
    position.beforeId = conversations[0].id;
  } else if (targetIndex >= conversations.length) {
    // Insert at end
    if (conversations.length > 0) {
      position.afterId = conversations[conversations.length - 1].id;
    }
  } else {
    // Insert between conversations
    if (targetIndex > 0) {
      position.afterId = conversations[targetIndex - 1].id;
    }
    position.beforeId = conversations[targetIndex].id;
  }
  
  return position;
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
  
  &--moving {
    pointer-events: none;
    
    .kanban-column__cards {
      opacity: 0.8;
    }
    
    &::after {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: linear-gradient(45deg, transparent 30%, rgba(255,255,255,0.1) 50%, transparent 70%);
      background-size: 200% 200%;
      animation: shimmer 1.5s infinite;
      pointer-events: none;
      z-index: 1;
    }
  }
  
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
    position: relative;
    
    &--drag-over {
      background-color: var(--column-accent);
      border-radius: var(--border-radius-normal);
    }
  }
  
  &__drop-indicator {
    height: 4px;
    background: linear-gradient(90deg, var(--w-500) 0%, var(--w-400) 100%);
    border-radius: var(--border-radius-full);
    margin: var(--space-micro) 0;
    opacity: 0.8;
    box-shadow: 0 0 8px var(--w-300);
    animation: pulse-glow 1s ease-in-out infinite alternate;
  }
}

.kanban-conversation-item {
  transition: all 0.2s ease;
  
  &.dragging {
    opacity: 0.5;
    transform: scale(0.98);
  }
  
  &:hover {
    transform: translateY(-1px);
  }
}

@keyframes pulse-glow {
  from {
    opacity: 0.6;
    transform: scaleY(0.8);
  }
  to {
    opacity: 1;
    transform: scaleY(1);
  }
}

@keyframes shimmer {
  0% {
    background-position: -200% -200%;
  }
  100% {
    background-position: 200% 200%;
  }
}
</style>