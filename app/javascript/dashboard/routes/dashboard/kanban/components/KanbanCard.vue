<template>
  <div
    class="kanban-card"
    :class="{ 'kanban-card--unread': hasUnread, 'kanban-card--moving': isMoving }"
    :data-conversation-id="conversation.id"
    draggable="true"
    @dragstart="handleDragStart"
    @dragend="handleDragEnd"
    @click="openConversation"
  >
    <div class="kanban-card__header">
      <div class="kanban-card__contact">
        <Thumbnail
          :src="conversation.contact.avatar_url"
          :username="conversation.contact.name"
          size="24px"
        />
        <div class="kanban-card__contact-info">
          <h4>{{ conversation.contact.name || conversation.contact.email || conversation.contact.phone_number }}</h4>
          <p class="kanban-card__inbox">
            <fluent-icon :icon="inboxIcon" size="12" />
            {{ conversation.inbox.name }}
          </p>
        </div>
      </div>
      <div v-if="hasUnread" class="kanban-card__unread-badge">
        {{ conversation.unread_count }}
      </div>
    </div>
    
    <div class="kanban-card__body">
      <p class="kanban-card__subject">
        #{{ conversation.display_id }} - {{ conversationSubject }}
      </p>
      
      <div class="kanban-card__meta">
        <div v-if="conversation.assignee" class="kanban-card__assignee">
          <Thumbnail
            :src="conversation.assignee.avatar_url"
            :username="conversation.assignee.name"
            size="20px"
          />
          <span>{{ conversation.assignee.available_name }}</span>
        </div>
        
        <div v-if="conversation.priority" class="kanban-card__priority">
          <PriorityMark :priority="conversation.priority" />
        </div>
      </div>
      
      <div v-if="conversation.labels.length" class="kanban-card__labels">
        <span
          v-for="label in conversation.labels"
          :key="label"
          class="kanban-card__label"
        >
          {{ label }}
        </span>
      </div>
    </div>
    
    <div class="kanban-card__footer">
      <TimeAgo
        :timestamp="conversation.last_activity_at"
        class="kanban-card__time"
      />
      <span 
        class="kanban-card__status"
        :class="`kanban-card__status--${conversation.status}`"
      >
        {{ $t(`CONVERSATION.STATUS.${conversation.status.toUpperCase()}`) }}
      </span>
    </div>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import PriorityMark from 'dashboard/components/widgets/conversation/PriorityMark.vue';
import { getInboxClassByType } from 'dashboard/helper/inbox';

export default {
  name: 'KanbanCard',
  components: {
    Thumbnail,
    TimeAgo,
    PriorityMark,
  },
  props: {
    conversation: {
      type: Object,
      required: true,
    },
    isMoving: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    hasUnread() {
      return this.conversation.unread_count > 0;
    },
    conversationSubject() {
      // You might want to fetch the last message or use a custom attribute
      return this.conversation.meta?.subject || this.$t('KANBAN.NO_SUBJECT');
    },
    inboxIcon() {
      const iconMap = {
        'Channel::WebWidget': 'chat',
        'Channel::FacebookPage': 'brand-facebook',
        'Channel::TwitterProfile': 'brand-twitter',
        'Channel::Email': 'mail',
        'Channel::Whatsapp': 'brand-whatsapp',
        'Channel::Sms': 'chat-help',
        'Channel::Telegram': 'send',
      };
      return iconMap[this.conversation.inbox.channel_type] || 'chat';
    },
  },
  methods: {
    handleDragStart(event) {
      event.dataTransfer.effectAllowed = 'move';
      event.dataTransfer.setData('conversationId', this.conversation.id);
      event.dataTransfer.setData('fromStage', this.$parent.stage.key);
      event.target.classList.add('dragging');
    },
    
    handleDragEnd(event) {
      event.target.classList.remove('dragging');
    },
    
    openConversation() {
      this.$router.push({
        name: 'inbox_conversation',
        params: {
          accountId: this.$route.params.accountId,
          conversation_id: this.conversation.id,
        },
      });
    },
  },
};
</script>

<style scoped lang="scss">
.kanban-card {
  background-color: var(--white);
  border: 1px solid var(--s-200);
  border-radius: var(--border-radius-normal);
  padding: var(--space-small);
  cursor: move;
  transition: all 0.2s ease;
  
  &:hover {
    box-shadow: var(--shadow-medium);
    transform: translateY(-2px);
  }
  
  &.dragging {
    opacity: 0.5;
  }
  
  &--unread {
    border-left: 3px solid var(--w-500);
    background-color: var(--w-25);
  }
  
  &--moving {
    pointer-events: none;
  }
  
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: var(--space-small);
  }
  
  &__contact {
    display: flex;
    gap: var(--space-small);
    flex: 1;
  }
  
  &__contact-info {
    flex: 1;
    min-width: 0;
    
    h4 {
      margin: 0;
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
      color: var(--s-900);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  
  &__inbox {
    display: flex;
    align-items: center;
    gap: 4px;
    margin: 2px 0 0;
    font-size: var(--font-size-mini);
    color: var(--s-600);
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
  }
  
  &__body {
    margin-bottom: var(--space-small);
  }
  
  &__subject {
    margin: 0 0 var(--space-micro);
    font-size: var(--font-size-small);
    color: var(--s-700);
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
  
  &__meta {
    display: flex;
    gap: var(--space-small);
    align-items: center;
    margin-bottom: var(--space-micro);
  }
  
  &__assignee {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: var(--font-size-mini);
    color: var(--s-600);
    
    span {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 100px;
    }
  }
  
  &__priority {
    margin-left: auto;
  }
  
  &__labels {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    margin-top: var(--space-micro);
  }
  
  &__label {
    padding: 2px 6px;
    border-radius: var(--border-radius-small);
    background-color: var(--s-100);
    color: var(--s-700);
    font-size: var(--font-size-mini);
  }
  
  &__footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: var(--space-micro);
    border-top: 1px solid var(--s-100);
  }
  
  &__time {
    font-size: var(--font-size-mini);
    color: var(--s-500);
  }
  
  &__status {
    padding: 2px 6px;
    border-radius: var(--border-radius-small);
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-medium);
    
    &--open {
      background-color: var(--g-100);
      color: var(--g-800);
    }
    
    &--resolved {
      background-color: var(--s-100);
      color: var(--s-700);
    }
    
    &--pending {
      background-color: var(--y-100);
      color: var(--y-800);
    }
    
    &--snoozed {
      background-color: var(--b-100);
      color: var(--b-800);
    }
  }
}
</style>