<template>
  <div
    class="kanban-card"
    :class="cardClasses"
    :data-conversation-id="conversation.id"
    draggable="true"
    @dragstart="handleDragStart"
    @dragend="handleDragEnd"
    @click="openConversation"
  >
    <!-- Enhanced Header with Contact and Channel Info -->
    <div class="kanban-card__header">
      <div class="kanban-card__contact">
        <Thumbnail
          :src="conversation.contact?.avatar_url"
          :username="contactDisplayName"
          size="28px"
        />
        <div class="kanban-card__contact-info">
          <h4>{{ contactDisplayName }}</h4>
          <div class="kanban-card__channel">
            <fluent-icon :icon="channelIcon" size="12" />
            <span>{{ conversation.inbox?.name }}</span>
          </div>
        </div>
      </div>
      <div class="kanban-card__indicators">
        <div v-if="conversation.priority" class="kanban-card__priority">
          <fluent-icon :icon="priorityIcon" size="14" />
        </div>
        <div v-if="hasUnread" class="kanban-card__unread-badge">
          {{ conversation.unread_count }}
        </div>
      </div>
    </div>
    
    <!-- Enhanced Body with Message Preview -->
    <div class="kanban-card__body">
      <div class="kanban-card__id">
        <span>#{{ conversation.display_id }}</span>
        <time-ago
          :timestamp="conversation.last_activity_at"
          class="kanban-card__time"
        />
      </div>
      
      <p v-if="lastMessagePreview" class="kanban-card__message">
        {{ lastMessagePreview }}
      </p>
      
      <div v-if="conversation.labels?.length" class="kanban-card__labels">
        <span
          v-for="label in displayLabels"
          :key="label.id"
          class="kanban-card__label"
          :style="{ backgroundColor: label.color + '20', borderColor: label.color + '50', color: label.color }"
        >
          {{ label.title }}
        </span>
        <span v-if="extraLabelsCount > 0" class="kanban-card__label-more">
          +{{ extraLabelsCount }}
        </span>
      </div>
    </div>
    
    <!-- Enhanced Footer with Assignee and Actions -->
    <div class="kanban-card__footer">
      <div class="kanban-card__assignee">
        <template v-if="conversation.assignee">
          <thumbnail
            :src="conversation.assignee.avatar_url"
            :username="conversation.assignee.name"
            size="20px"
          />
          <span>{{ conversation.assignee.available_name }}</span>
        </template>
        <span v-else class="kanban-card__unassigned">
          {{ $t('KANBAN.CARD.UNASSIGNED') }}
        </span>
      </div>
      
      <div class="kanban-card__status-indicator" :class="`status--${conversation.status}`">
        <fluent-icon :icon="statusIcon" size="12" />
      </div>
    </div>
    
    <!-- Quick Actions (visible on hover) -->
    <div class="kanban-card__actions">
      <button
        class="kanban-card__action"
        :title="$t('KANBAN.CARD.QUICK_REPLY')"
        @click.stop="quickReply"
      >
        <fluent-icon icon="chat" size="14" />
      </button>
      <button
        class="kanban-card__action"
        :title="$t('KANBAN.CARD.ASSIGN')"
        @click.stop="assignConversation"
      >
        <fluent-icon icon="person" size="14" />
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  isMoving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['quickReply', 'assign']);
const router = useRouter();
const route = useRoute();
const { t } = useI18n();

// Computed properties
const hasUnread = computed(() => {
  return (props.conversation.unread_count || 0) > 0;
});

const contactDisplayName = computed(() => {
  const contact = props.conversation.contact || {};
  return contact.name || contact.email || contact.phone_number || t('KANBAN.CARD.UNKNOWN_CONTACT');
});

const lastMessagePreview = computed(() => {
  const lastMessage = props.conversation.last_message;
  if (!lastMessage?.content) return null;
  
  // Extract text from HTML content and truncate
  const textContent = lastMessage.content.replace(/<[^>]*>/g, '').trim();
  return textContent.length > 80 ? textContent.substring(0, 80) + '...' : textContent;
});

const channelIcon = computed(() => {
  const iconMap = {
    'Channel::WebWidget': 'chat',
    'Channel::FacebookPage': 'brand-facebook', 
    'Channel::TwitterProfile': 'brand-twitter',
    'Channel::Email': 'mail',
    'Channel::Whatsapp': 'brand-whatsapp',
    'Channel::Sms': 'chat-help',
    'Channel::Telegram': 'send',
    'Channel::InstagramDirectMessage': 'brand-instagram',
  };
  return iconMap[props.conversation.inbox?.channel_type] || 'chat';
});

const priorityIcon = computed(() => {
  const priorityMap = {
    urgent: 'alert-triangle',
    high: 'trending-up',
    medium: 'minus',
    low: 'trending-down',
  };
  return priorityMap[props.conversation.priority] || 'minus';
});

const statusIcon = computed(() => {
  const statusMap = {
    open: 'circle',
    resolved: 'checkmark-circle',
    pending: 'clock',
    snoozed: 'sleep',
  };
  return statusMap[props.conversation.status] || 'circle';
});

// Enhanced label display (show max 3, then +N)
const displayLabels = computed(() => {
  return (props.conversation.labels || []).slice(0, 3);
});

const extraLabelsCount = computed(() => {
  const totalLabels = props.conversation.labels?.length || 0;
  return Math.max(0, totalLabels - 3);
});

const cardClasses = computed(() => ({
  'kanban-card--unread': hasUnread.value,
  'kanban-card--moving': props.isMoving,
  'kanban-card--urgent': props.conversation.priority === 'urgent',
  'kanban-card--high': props.conversation.priority === 'high',
}));

// Methods
const handleDragStart = (event) => {
  event.dataTransfer.effectAllowed = 'move';
  event.dataTransfer.setData('conversationId', props.conversation.id.toString());
  event.dataTransfer.setData('fromStage', route.params.stageKey || 'unknown');
  
  // Modern drag approach: Use real card with elegant scaling
  const dragImage = event.target.cloneNode(true);
  
  // Style the drag image for better UX (like Linear, Notion, etc.)
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
    background: white;
  `;
  
  // Temporarily add to DOM
  document.body.appendChild(dragImage);
  
  // Set the real card as drag image with slight offset for natural feel
  const rect = event.target.getBoundingClientRect();
  const offsetX = event.clientX - rect.left;
  const offsetY = event.clientY - rect.top;
  event.dataTransfer.setDragImage(dragImage, offsetX, offsetY);
  
  // Add dragging state to original card
  event.target.classList.add('dragging');
  
  // Clean up drag image after browser captures it
  setTimeout(() => {
    if (dragImage.parentNode) {
      document.body.removeChild(dragImage);
    }
  }, 0);
};

const handleDragEnd = (event) => {
  event.target.classList.remove('dragging');
};

const openConversation = () => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: route.params.accountId,
      conversation_id: props.conversation.id,
    },
  });
};

const quickReply = () => {
  emit('quickReply', props.conversation);
};

const assignConversation = () => {
  emit('assign', props.conversation);
};
</script>

<style scoped lang="scss">
.kanban-card {
  background-color: var(--white);
  border: 1px solid var(--s-200);
  border-radius: var(--border-radius-large);
  padding: var(--space-large);
  cursor: grab;
  transition: all 0.2s ease;
  position: relative;
  margin-bottom: var(--space-normal);
  overflow: hidden;
  
  &:active {
    cursor: grabbing;
  }
  
  &:hover {
    box-shadow: var(--shadow-large);
    transform: translateY(-2px);
    border-color: var(--w-300);
    
    .kanban-card__actions {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  &.dragging {
    opacity: 0.3;
    transform: scale(0.98) rotate(2deg);
    box-shadow: var(--shadow-large);
    cursor: grabbing;
    transition: all 0.2s cubic-bezier(0.2, 0, 0, 1);
    z-index: 1;
  }
  
  &--unread {
    border-left: 4px solid var(--w-500);
    background: linear-gradient(135deg, var(--w-25) 0%, var(--white) 100%);
    box-shadow: var(--shadow-medium);
    
    &::before {
      content: '';
      position: absolute;
      top: 0;
      right: 0;
      width: 0;
      height: 0;
      border-style: solid;
      border-width: 0 12px 12px 0;
      border-color: transparent var(--w-500) transparent transparent;
    }
  }
  
  &--urgent {
    border-left: 4px solid var(--r-500);
    background: linear-gradient(135deg, var(--r-25) 0%, var(--white) 100%);
  }
  
  &--high {
    border-left: 4px solid var(--y-500);
    background: linear-gradient(135deg, var(--y-25) 0%, var(--white) 100%);
  }
  
  &--moving {
    pointer-events: none;
  }
  
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: var(--space-normal);
  }
  
  &__contact {
    display: flex;
    gap: var(--space-normal);
    flex: 1;
    min-width: 0;
  }
  
  &__contact-info {
    flex: 1;
    min-width: 0;
    
    h4 {
      margin: 0 0 var(--space-micro);
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      line-height: 1.4;
    }
  }
  
  &__channel {
    display: flex;
    align-items: center;
    gap: var(--space-micro);
    font-size: var(--font-size-mini);
    color: var(--s-600);
    
    span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 120px;
    }
  }
  
  &__indicators {
    display: flex;
    align-items: center;
    gap: var(--space-small);
  }
  
  &__priority {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    border-radius: var(--border-radius-small);
    
    &:has([icon=\"alert-triangle\"]) {
      background-color: var(--r-100);
      color: var(--r-600);
    }
    
    &:has([icon=\"trending-up\"]) {
      background-color: var(--y-100);
      color: var(--y-600);
    }
  }
  
  &__unread-badge {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 20px;
    height: 20px;
    padding: 0 6px;
    border-radius: var(--border-radius-full);
    background-color: var(--r-500);
    color: var(--white);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-bold);
    box-shadow: var(--shadow-small);
  }
  
  &__body {
    margin-bottom: var(--space-normal);
  }
  
  &__id {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-small);
    
    span {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-bold);
      color: var(--s-700);
      background-color: var(--s-50);
      padding: 2px 8px;
      border-radius: var(--border-radius-small);
    }
  }
  
  &__time {
    font-size: var(--font-size-mini);
    color: var(--s-500);
  }
  
  &__message {
    margin: 0 0 var(--space-normal);
    font-size: var(--font-size-small);
    color: var(--s-700);
    line-height: 1.5;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    -webkit-box-orient: vertical;
    background-color: var(--s-25);
    padding: var(--space-small);
    border-radius: var(--border-radius-small);
    border-left: 3px solid var(--s-200);
  }
  
  &__labels {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-micro);
    margin-bottom: var(--space-small);
  }
  
  &__label {
    padding: 3px 8px;
    border-radius: var(--border-radius-full);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
    border: 1px solid;
    white-space: nowrap;
    max-width: 80px;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  
  &__label-more {
    padding: 3px 8px;
    border-radius: var(--border-radius-full);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
    background-color: var(--s-200);
    color: var(--s-700);
    border: 1px solid var(--s-300);
  }
  
  &__footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: var(--space-small);
    border-top: 1px solid var(--s-100);
  }
  
  &__assignee {
    display: flex;
    align-items: center;
    gap: var(--space-small);
    font-size: var(--font-size-small);
    color: var(--s-700);
    flex: 1;
    min-width: 0;
    
    span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      font-weight: var(--font-weight-medium);
    }
  }
  
  &__unassigned {
    font-style: italic;
    color: var(--s-500);
  }
  
  &__status-indicator {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    border-radius: var(--border-radius-full);
    
    &.status--open {
      background-color: var(--g-100);
      color: var(--g-600);
    }
    
    &.status--resolved {
      background-color: var(--s-100);
      color: var(--s-600);
    }
    
    &.status--pending {
      background-color: var(--y-100);
      color: var(--y-600);
    }
    
    &.status--snoozed {
      background-color: var(--w-100);
      color: var(--w-600);
    }
  }
  
  &__actions {
    position: absolute;
    top: var(--space-small);
    right: var(--space-small);
    display: flex;
    gap: var(--space-micro);
    opacity: 0;
    transform: translateY(-5px);
    transition: all 0.2s ease;
    background-color: var(--white);
    padding: var(--space-micro);
    border-radius: var(--border-radius-small);
    box-shadow: var(--shadow-medium);
  }
  
  &__action {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    border: none;
    border-radius: var(--border-radius-small);
    background-color: var(--s-50);
    color: var(--s-600);
    cursor: pointer;
    transition: all 0.15s ease;
    
    &:hover {
      background-color: var(--w-100);
      color: var(--w-600);
      transform: scale(1.05);
    }
  }
}
</style>