<template>
  <div class="kanban-board">
    <!-- Filter Bar -->
    <div v-if="!isLoading && stages.length" class="kanban-filters">
      <KanbanFilters
        v-model:conversation-filters="conversationFilters"
        v-model:channel-filters="channelFilters"
        v-model:sort-options="sortOptions"
        :total-conversations="totalConversations"
        @reset-filters="resetFilters"
      />
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="kanban-loading">
      <Spinner />
      <p>{{ $t('KANBAN.LOADING') }}</p>
    </div>
    
    <!-- Empty State -->
    <div v-else-if="!stages.length" class="kanban-empty">
      <fluent-icon icon="view-dashboard" size="48" />
      <h3>{{ $t('KANBAN.NO_STAGES') }}</h3>
      <p>{{ $t('KANBAN.NO_STAGES_DESCRIPTION') }}</p>
      <Button
        v-if="isAdmin"
        icon="i-lucide-settings"
        :label="$t('KANBAN.CREATE_STAGES')"
        @click="$router.push({ name: 'kanban_stages' })"
      />
    </div>
    
    <!-- Kanban Board -->
    <div v-else class="kanban-board__container">
      <div class="kanban-board__columns">
        <KanbanColumn
          v-for="stage in stages"
          :key="stage.key"
          :stage="stage"
          :conversations="getFilteredConversationsByStage(stage.key)"
          :is-moving="isMoving"
          :filters="activeFilters"
          @drop="handleDrop"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAlert } from 'dashboard/composables';

import Spinner from 'shared/components/Spinner.vue';
import KanbanColumn from './components/KanbanColumn.vue';
import KanbanFilters from './components/KanbanFilters.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const { isAdmin } = useAdmin();

// Board configuration
const boardKey = ref('sales');

// Filter states
const conversationFilters = ref({
  status: [],
  priority: [],
  assignee: null,
  labels: [],
  dateRange: null,
});

const channelFilters = ref({
  channels: [], // ['web_widget', 'facebook', 'instagram', 'whatsapp', 'email']
});

const sortOptions = ref({
  field: 'updated_at', // 'updated_at', 'created_at', 'priority'
  direction: 'desc', // 'asc', 'desc'
});

// Store getters
const stages = computed(() => getters['kanban/getActiveStages'].value);
const allConversations = computed(() => getters['kanban/getAllConversations'].value);
const isLoading = computed(() => getters['kanban/isLoading'].value);
const isMoving = computed(() => getters['kanban/isMoving'].value);

// Computed properties for filtering
const activeFilters = computed(() => ({
  ...conversationFilters.value,
  ...channelFilters.value,
  ...sortOptions.value,
}));

const totalConversations = computed(() => {
  return allConversations.value?.length || 0;
});

// Filter conversations based on active filters
const getFilteredConversationsByStage = (stageKey) => {
  const stageConversations = getters['kanban/getConversationsByStage'].value(stageKey);
  
  if (!stageConversations?.length) return [];
  
  return stageConversations.filter(conversation => {
    // Status filter
    if (conversationFilters.value.status.length > 0) {
      if (!conversationFilters.value.status.includes(conversation.status)) {
        return false;
      }
    }
    
    // Channel filter
    if (channelFilters.value.channels.length > 0) {
      if (!channelFilters.value.channels.includes(conversation.inbox?.channel_type)) {
        return false;
      }
    }
    
    // Priority filter
    if (conversationFilters.value.priority.length > 0) {
      if (!conversationFilters.value.priority.includes(conversation.priority)) {
        return false;
      }
    }
    
    // Assignee filter
    if (conversationFilters.value.assignee) {
      if (conversation.assignee?.id !== conversationFilters.value.assignee) {
        return false;
      }
    }
    
    // Label filter
    if (conversationFilters.value.labels.length > 0) {
      const conversationLabels = conversation.labels?.map(label => label.id) || [];
      const hasMatchingLabel = conversationFilters.value.labels.some(labelId => 
        conversationLabels.includes(labelId)
      );
      if (!hasMatchingLabel) {
        return false;
      }
    }
    
    return true;
  }).sort((a, b) => {
    const field = sortOptions.value.field;
    const direction = sortOptions.value.direction;
    
    let aValue = a[field];
    let bValue = b[field];
    
    // Handle date fields
    if (field.includes('_at')) {
      aValue = new Date(aValue);
      bValue = new Date(bValue);
    }
    
    // Handle priority (assuming numeric or string priority)
    if (field === 'priority') {
      const priorityOrder = { urgent: 4, high: 3, medium: 2, low: 1, null: 0 };
      aValue = priorityOrder[aValue] || 0;
      bValue = priorityOrder[bValue] || 0;
    }
    
    if (direction === 'asc') {
      return aValue > bValue ? 1 : -1;
    } else {
      return aValue < bValue ? 1 : -1;
    }
  });
};

// Methods
const resetFilters = () => {
  conversationFilters.value = {
    status: [],
    priority: [],
    assignee: null,
    labels: [],
    dateRange: null,
  };
  channelFilters.value = {
    channels: [],
  };
  sortOptions.value = {
    field: 'updated_at',
    direction: 'desc',
  };
};

const handleDrop = async ({ conversationId, fromStage, toStage, position }) => {
  try {
    await store.dispatch('kanban/moveConversation', {
      conversationId,
      fromStage,
      toStage,
      position,
    });
  } catch (error) {
    useAlert(t('KANBAN.MOVE_ERROR'));
  }
};

// ActionCable integration
const setupKanbanSubscription = () => {
  // Add kanban-specific events to the existing ActionCable events
  const kanbanEvents = {
    'kanban.stage.updated': (data) => {
      store.dispatch('kanban/updateStageFromSocket', data);
    },
    'kanban.conversation.moved': (data) => {
      store.dispatch('kanban/updateConversationPositionFromSocket', data);
    },
    'conversation.updated': (data) => {
      // Update conversation in kanban view if it affects stage position
      if (data.custom_attributes?.kanban_stage) {
        store.dispatch('kanban/updateConversationFromSocket', data);
      }
    },
    'conversation.created': (data) => {
      // Add new conversation to appropriate stage
      store.dispatch('kanban/addConversationFromSocket', data);
    },
    'assignee.changed': (data) => {
      // Update assignee in kanban cards
      store.dispatch('kanban/updateConversationFromSocket', data);
    },
    'conversation.status_changed': (data) => {
      // Update status in kanban cards
      store.dispatch('kanban/updateConversationFromSocket', data);
    },
  };
  
  // Register kanban events with the existing ActionCable connector
  Object.entries(kanbanEvents).forEach(([eventName, handler]) => {
    // This assumes the store has a method to register additional WebSocket events
    store.dispatch('registerWebSocketEvent', { eventName, handler });
  });
};

// Lifecycle
onMounted(async () => {
  await store.dispatch('kanban/fetchBoard', boardKey.value);
  setupKanbanSubscription();
});

onBeforeUnmount(() => {
  // Cleanup any kanban-specific subscriptions
  store.dispatch('kanban/cleanup');
});
</script>

<style scoped lang="scss">
.kanban-board {
  flex: 1;
  overflow: hidden;
  position: relative;
  background: linear-gradient(135deg, var(--s-25) 0%, var(--s-50) 100%);

  &__container {
    height: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    padding: var(--space-large) var(--space-mega);
  }

  &__columns {
    display: flex;
    gap: var(--space-mega);
    height: 100%;
    min-width: max-content;
    align-items: flex-start;
    padding-bottom: var(--space-large);
  }
}

.kanban-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: var(--space-normal);
  
  p {
    color: var(--s-600);
    font-size: var(--font-size-default);
  }
}

.kanban-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  gap: var(--space-large);
  text-align: center;
  padding: var(--space-mega);
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  box-shadow: var(--shadow-small);
  margin: var(--space-large);
  
  h3 {
    margin: 0;
    font-size: var(--font-size-mega);
    font-weight: var(--font-weight-bold);
    color: var(--s-900);
  }
  
  p {
    margin: 0;
    color: var(--s-600);
    font-size: var(--font-size-default);
    max-width: 500px;
    line-height: 1.6;
  }
  
  .button {
    margin-top: var(--space-normal);
  }
}
</style>