<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationFilters: {
    type: Object,
    required: true,
  },
  channelFilters: {
    type: Object,
    required: true,
  },
  sortOptions: {
    type: Object,
    required: true,
  },
  totalConversations: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits([
  'update:conversationFilters',
  'update:channelFilters', 
  'update:sortOptions',
  'resetFilters',
]);

const { t } = useI18n();
const getters = useStoreGetters();

// Available filter options
const statusOptions = computed(() => [
  { value: 'open', label: t('KANBAN.FILTERS.STATUS.OPEN') },
  { value: 'pending', label: t('KANBAN.FILTERS.STATUS.PENDING') },
  { value: 'resolved', label: t('KANBAN.FILTERS.STATUS.RESOLVED') },
]);

const priorityOptions = computed(() => [
  { value: 'urgent', label: t('KANBAN.FILTERS.PRIORITY.URGENT') },
  { value: 'high', label: t('KANBAN.FILTERS.PRIORITY.HIGH') },
  { value: 'medium', label: t('KANBAN.FILTERS.PRIORITY.MEDIUM') },
  { value: 'low', label: t('KANBAN.FILTERS.PRIORITY.LOW') },
]);

const channelOptions = computed(() => [
  { value: 'web_widget', label: t('KANBAN.FILTERS.CHANNELS.WEB_WIDGET'), icon: 'i-lucide-globe' },
  { value: 'facebook', label: t('KANBAN.FILTERS.CHANNELS.FACEBOOK'), icon: 'i-lucide-facebook' },
  { value: 'instagram', label: t('KANBAN.FILTERS.CHANNELS.INSTAGRAM'), icon: 'i-lucide-instagram' },
  { value: 'whatsapp', label: t('KANBAN.FILTERS.CHANNELS.WHATSAPP'), icon: 'i-lucide-phone' },
  { value: 'email', label: t('KANBAN.FILTERS.CHANNELS.EMAIL'), icon: 'i-lucide-mail' },
]);

const sortFieldOptions = computed(() => [
  { value: 'updated_at', label: t('KANBAN.FILTERS.SORT.LAST_ACTIVITY') },
  { value: 'created_at', label: t('KANBAN.FILTERS.SORT.CREATED_DATE') },
  { value: 'priority', label: t('KANBAN.FILTERS.SORT.PRIORITY') },
]);

// Get agents for assignee dropdown
const agents = computed(() => getters['agents/getAgents'].value || []);
const labels = computed(() => getters['labels/getLabels'].value || []);

// Filter state management
const updateConversationFilters = (key, value) => {
  emit('update:conversationFilters', {
    ...props.conversationFilters,
    [key]: value,
  });
};

const updateChannelFilters = (value) => {
  emit('update:channelFilters', {
    channels: value,
  });
};

const updateSortOptions = (key, value) => {
  emit('update:sortOptions', {
    ...props.sortOptions,
    [key]: value,
  });
};

// Active filter count for badge
const activeFilterCount = computed(() => {
  let count = 0;
  if (props.conversationFilters.status.length > 0) count++;
  if (props.conversationFilters.priority.length > 0) count++;
  if (props.conversationFilters.assignee) count++;
  if (props.conversationFilters.labels.length > 0) count++;
  if (props.channelFilters.channels.length > 0) count++;
  return count;
});

const hasActiveFilters = computed(() => activeFilterCount.value > 0);
</script>

<template>
  <div class="kanban-filters">
    <div class="kanban-filters__main">
      <!-- Status Filter -->
      <div class="filter-group">
        <label class="filter-label">{{ $t('KANBAN.FILTERS.STATUS.LABEL') }}</label>
        <woot-input
          type="select"
          multiple
          :value="conversationFilters.status"
          :placeholder="$t('KANBAN.FILTERS.STATUS.PLACEHOLDER')"
          @input="updateConversationFilters('status', $event)"
        >
          <option
            v-for="option in statusOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </woot-input>
      </div>

      <!-- Channel Filter -->
      <div class="filter-group">
        <label class="filter-label">{{ $t('KANBAN.FILTERS.CHANNELS.LABEL') }}</label>
        <woot-input
          type="select"
          multiple
          :value="channelFilters.channels"
          :placeholder="$t('KANBAN.FILTERS.CHANNELS.PLACEHOLDER')"
          @input="updateChannelFilters($event)"
        >
          <option
            v-for="option in channelOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </woot-input>
      </div>

      <!-- Priority Filter -->
      <div class="filter-group">
        <label class="filter-label">{{ $t('KANBAN.FILTERS.PRIORITY.LABEL') }}</label>
        <woot-input
          type="select"
          multiple
          :value="conversationFilters.priority"
          :placeholder="$t('KANBAN.FILTERS.PRIORITY.PLACEHOLDER')"
          @input="updateConversationFilters('priority', $event)"
        >
          <option
            v-for="option in priorityOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </woot-input>
      </div>

      <!-- Assignee Filter -->
      <div class="filter-group">
        <label class="filter-label">{{ $t('KANBAN.FILTERS.ASSIGNEE.LABEL') }}</label>
        <woot-input
          type="select"
          :value="conversationFilters.assignee"
          :placeholder="$t('KANBAN.FILTERS.ASSIGNEE.PLACEHOLDER')"
          @input="updateConversationFilters('assignee', $event)"
        >
          <option value="">{{ $t('KANBAN.FILTERS.ASSIGNEE.ALL') }}</option>
          <option
            v-for="agent in agents"
            :key="agent.id"
            :value="agent.id"
          >
            {{ agent.name }}
          </option>
        </woot-input>
      </div>
    </div>

    <div class="kanban-filters__actions">
      <!-- Sort Options -->
      <div class="filter-group filter-group--sort">
        <woot-input
          type="select"
          :value="sortOptions.field"
          @input="updateSortOptions('field', $event)"
        >
          <option
            v-for="option in sortFieldOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </woot-input>
        
        <Button
          :icon="sortOptions.direction === 'asc' ? 'i-lucide-arrow-up' : 'i-lucide-arrow-down'"
          slate
          faded
          xs
          @click="updateSortOptions('direction', sortOptions.direction === 'asc' ? 'desc' : 'asc')"
        />
      </div>

      <!-- Filter Actions -->
      <div class="filter-actions">
        <span v-if="hasActiveFilters" class="filter-count">
          {{ $t('KANBAN.FILTERS.ACTIVE_COUNT', { count: activeFilterCount }) }}
        </span>
        
        <Button
          v-if="hasActiveFilters"
          icon="i-lucide-x"
          slate
          faded
          xs
          :label="$t('KANBAN.FILTERS.CLEAR_ALL')"
          @click="$emit('resetFilters')"
        />
        
        <span class="conversation-count">
          {{ $t('KANBAN.FILTERS.TOTAL_CONVERSATIONS', { count: totalConversations }) }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.kanban-filters {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: var(--space-large);
  padding: var(--space-large) var(--space-mega);
  background-color: var(--white);
  border-bottom: 1px solid var(--s-100);
  
  &__main {
    display: flex;
    gap: var(--space-normal);
    flex: 1;
  }
  
  &__actions {
    display: flex;
    align-items: center;
    gap: var(--space-normal);
  }
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
  min-width: 180px;
  
  &--sort {
    flex-direction: row;
    align-items: flex-end;
    min-width: auto;
    gap: var(--space-small);
    
    .woot-input {
      min-width: 150px;
    }
  }
  
  .filter-label {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    color: var(--s-700);
    margin-bottom: var(--space-smaller);
  }
}

.filter-actions {
  display: flex;
  align-items: center;
  gap: var(--space-normal);
  
  .filter-count {
    font-size: var(--font-size-small);
    color: var(--w-600);
    font-weight: var(--font-weight-medium);
  }
  
  .conversation-count {
    font-size: var(--font-size-small);
    color: var(--s-600);
  }
}

@media (max-width: 1024px) {
  .kanban-filters {
    flex-direction: column;
    align-items: stretch;
    gap: var(--space-normal);
    
    &__main {
      flex-wrap: wrap;
    }
    
    &__actions {
      justify-content: space-between;
    }
  }
  
  .filter-group {
    min-width: 150px;
  }
}

@media (max-width: 768px) {
  .kanban-filters {
    padding: var(--space-normal);
    
    &__main {
      flex-direction: column;
    }
    
    &__actions {
      flex-direction: column;
      align-items: stretch;
      gap: var(--space-small);
    }
  }
  
  .filter-group {
    min-width: auto;
    
    &--sort {
      flex-direction: column;
    }
  }
}
</style>