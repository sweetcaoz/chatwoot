<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();

// Reactive state
const localStages = ref([]);
const showStageModal = ref(false);
const showDeleteModal = ref(false);
const editingStage = ref(null);
const deletingStage = ref(null);
const isSaving = ref(false);
const errors = ref({});

// Form state
const stageForm = ref({
  name: '',
  key: '',
  color: '#0EA5E9',
  icon: 'flag',
  board_key: 'sales',
});

// Configuration data
const predefinedColors = [
  '#0EA5E9', // Blue
  '#8B5CF6', // Purple  
  '#F59E0B', // Amber
  '#10B981', // Green
  '#EF4444', // Red
  '#6B7280', // Gray
  '#EC4899', // Pink
  '#14B8A6', // Teal
];

const iconOptions = [
  { value: 'flag', label: 'Flag' },
  { value: 'sparkle', label: 'New' },
  { value: 'person-check', label: 'Qualified' },
  { value: 'document', label: 'Document' },
  { value: 'chat-multiple', label: 'Discussion' },
  { value: 'checkmark-circle', label: 'Complete' },
  { value: 'clock', label: 'Waiting' },
  { value: 'star', label: 'Important' },
  { value: 'call', label: 'Call' },
  { value: 'mail', label: 'Email' },
  { value: 'briefcase', label: 'Deal' },
  { value: 'rocket', label: 'Launch' },
  { value: 'pause', label: 'On Hold' },
  { value: 'dismiss-circle', label: 'Canceled' },
  { value: 'arrow-growth', label: 'Progress' },
];

// Store getters
const stages = computed(() => getters['kanban/getStages'].value || []);
const isLoading = computed(() => getters['kanban/isLoading'].value);

// Computed properties
const deleteMessage = computed(() => {
  if (!deletingStage.value) return '';
  return deletingStage.value.name;
});

// Watchers
watch(
  stages,
  (newStages) => {
    localStages.value = [...newStages];
  },
  { immediate: true }
);

watch(
  () => stageForm.value.name,
  (newName) => {
    if (!editingStage.value && newName) {
      stageForm.value.key = newName
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9_]/g, '');
    }
  }
);

// Methods
const fetchStagesData = async () => {
  await store.dispatch('kanban/fetchStages');
};

const handleReorder = async () => {
  const stageIds = localStages.value.map(stage => stage.id);
  try {
    await store.dispatch('kanban/reorderStages', stageIds);
    useAlert(t('KANBAN.STAGE_MANAGER.REORDER_SUCCESS'));
  } catch (error) {
    useAlert(t('KANBAN.STAGE_MANAGER.REORDER_ERROR'));
    // Revert changes
    localStages.value = [...stages.value];
  }
};

const editStage = (stage) => {
  editingStage.value = stage;
  stageForm.value = {
    name: stage.name,
    key: stage.key,
    color: stage.color,
    icon: stage.icon || 'flag',
    board_key: stage.board_key,
  };
  showStageModal.value = true;
};

const saveStage = async () => {
  errors.value = {};
  
  // Validation
  if (!stageForm.value.name.trim()) {
    errors.value.name = t('KANBAN.STAGE_MANAGER.NAME_REQUIRED');
    return;
  }
  
  // Auto-generate key if not set
  if (!stageForm.value.key) {
    stageForm.value.key = stageForm.value.name
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
  }
  
  isSaving.value = true;
  try {
    if (editingStage.value) {
      await store.dispatch('kanban/updateStage', {
        id: editingStage.value.id,
        ...stageForm.value,
      });
      useAlert(t('KANBAN.STAGE_MANAGER.UPDATE_SUCCESS'));
    } else {
      await store.dispatch('kanban/createStage', stageForm.value);
      useAlert(t('KANBAN.STAGE_MANAGER.CREATE_SUCCESS'));
    }
    closeStageModal();
  } catch (error) {
    useAlert(error.message || t('KANBAN.STAGE_MANAGER.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const toggleStageStatus = async (stage, newValue) => {
  const originalValue = stage.active;
  stage.active = newValue;
  
  try {
    await store.dispatch('kanban/updateStage', {
      id: stage.id,
      active: newValue,
      board_key: stage.board_key,
    });
    useAlert(t('KANBAN.STAGE_MANAGER.STATUS_UPDATED'));
  } catch (error) {
    // Revert the change
    stage.active = originalValue;
    useAlert(error.message || t('KANBAN.STAGE_MANAGER.STATUS_ERROR'));
  }
};

const confirmDelete = (stage) => {
  deletingStage.value = stage;
  showDeleteModal.value = true;
};

const deleteStageAction = async () => {
  try {
    await store.dispatch('kanban/deleteStage', deletingStage.value.id);
    useAlert(t('KANBAN.STAGE_MANAGER.DELETE_SUCCESS'));
    closeDeleteModal();
  } catch (error) {
    useAlert(error.message || t('KANBAN.STAGE_MANAGER.DELETE_ERROR'));
  }
};

const openCreateModal = () => {
  editingStage.value = null;
  resetForm();
  showStageModal.value = true;
};

const closeStageModal = () => {
  showStageModal.value = false;
  editingStage.value = null;
  resetForm();
};

const closeDeleteModal = () => {
  showDeleteModal.value = false;
  deletingStage.value = null;
};

const resetForm = () => {
  stageForm.value = {
    name: '',
    key: '',
    color: '#0EA5E9',
    icon: 'flag',
    board_key: 'sales',
  };
  errors.value = {};
};

// Lifecycle
onMounted(() => {
  fetchStagesData();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('KANBAN.STAGE_MANAGER.LOADING')"
    :no-records-found="!localStages.length"
    :no-records-message="$t('KANBAN.STAGE_MANAGER.NO_STAGES')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('KANBAN.SETTINGS.TITLE')"
        :description="$t('KANBAN.SETTINGS.DESCRIPTION')"
        :link-text="$t('KANBAN.SETTINGS.LEARN_MORE')"
        feature-name="kanban"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('KANBAN.STAGE_MANAGER.ADD_STAGE')"
            @click="openCreateModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    
    <template #body>
      <div class="kanban-settings">
        <draggable
          v-model="localStages"
          :animation="200"
          handle=".stage-item__handle"
          class="kanban-settings__list"
          @end="handleReorder"
        >
          <template #item="{ element }">
            <div class="stage-item" :key="element.id">
              <div class="stage-item__handle">
                <fluent-icon icon="drag" size="16" />
              </div>
              
              <div class="stage-item__visual">
                <div class="stage-item__color">
                  <span 
                    class="stage-item__color-badge"
                    :style="{ backgroundColor: element.color }"
                  />
                </div>
                
                <div class="stage-item__icon">
                  <fluent-icon :icon="element.icon || 'flag'" size="18" />
                </div>
              </div>
              
              <div class="stage-item__info">
                <h4>{{ element.name }}</h4>
                <p>{{ element.key }}</p>
              </div>
              
              <div class="stage-item__stats">
                <span class="stage-item__count">
                  {{ element.conversations_count || 0 }}
                </span>
                <span class="stage-item__count-label">
                  {{ $t('KANBAN.STAGE_MANAGER.CONVERSATIONS') }}
                </span>
              </div>
              
              <div class="stage-item__status">
                <woot-switch
                  :value="element.active"
                  @input="toggleStageStatus(element, $event)"
                />
              </div>
              
              <div class="stage-item__actions">
                <Button
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="editStage(element)"
                />
                <Button
                  icon="i-lucide-trash-2"
                  ruby
                  xs
                  faded
                  @click="confirmDelete(element)"
                />
              </div>
            </div>
          </template>
        </draggable>
      </div>
    </template>
    
    <!-- Create/Edit Modal -->
    <woot-modal
      v-model:show="showStageModal"
      :on-close="closeStageModal"
    >
      <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header
          :header-title="editingStage ? $t('KANBAN.STAGE_MANAGER.EDIT_STAGE') : $t('KANBAN.STAGE_MANAGER.CREATE_STAGE')"
          :header-content="$t('KANBAN.STAGE_MANAGER.MODAL_DESCRIPTION')"
        />
        
        <form @submit.prevent="saveStage" class="flex flex-wrap mx-0">
          <woot-input
            v-model="stageForm.name"
            :class="{ error: errors.name }"
            class="w-full"
            :label="$t('KANBAN.STAGE_MANAGER.STAGE_NAME')"
            :placeholder="$t('KANBAN.STAGE_MANAGER.STAGE_NAME_PLACEHOLDER')"
            :error="errors.name"
            data-testid="stage-name"
            required
          />
          
          <div class="w-full">
            <label>
              {{ $t('KANBAN.STAGE_MANAGER.STAGE_COLOR') }}
              <woot-color-picker v-model="stageForm.color" />
            </label>
          </div>
          
          <div class="w-full">
            <label>
              {{ $t('KANBAN.STAGE_MANAGER.STAGE_ICON') }}
              <select
                v-model="stageForm.icon"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option
                  v-for="icon in iconOptions"
                  :key="icon.value"
                  :value="icon.value"
                >
                  {{ icon.label }}
                </option>
              </select>
            </label>
          </div>
          
          <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
            <Button
              faded
              slate
              type="reset"
              :label="$t('KANBAN.STAGE_MANAGER.CANCEL')"
              @click.prevent="closeStageModal"
            />
            <Button
              type="submit"
              data-testid="stage-submit"
              :label="editingStage ? $t('KANBAN.STAGE_MANAGER.UPDATE') : $t('KANBAN.STAGE_MANAGER.CREATE')"
              :disabled="!stageForm.name || isSaving"
              :is-loading="isSaving"
            />
          </div>
        </form>
      </div>
    </woot-modal>
    
    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-model:show="showDeleteModal"
      :on-close="closeDeleteModal"
      :on-confirm="deleteStageAction"
      :title="$t('KANBAN.STAGE_MANAGER.DELETE_TITLE')"
      :message="$t('KANBAN.STAGE_MANAGER.DELETE_MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('KANBAN.STAGE_MANAGER.DELETE')"
      :reject-text="$t('KANBAN.STAGE_MANAGER.CANCEL')"
    />
  </SettingsLayout>
</template>

<style scoped lang="scss">
.kanban-settings {
  &__list {
    display: flex;
    flex-direction: column;
    gap: var(--space-normal);
  }
}

.stage-item {
  display: flex;
  align-items: center;
  gap: var(--space-large);
  padding: var(--space-large);
  background-color: var(--white);
  border: 1px solid var(--s-200);
  border-radius: var(--border-radius-large);
  transition: all 0.2s ease;
  
  &:hover {
    background-color: var(--s-25);
    box-shadow: var(--shadow-medium);
    border-color: var(--s-300);
  }
  
  &__handle {
    cursor: move;
    color: var(--s-400);
    padding: var(--space-small);
    border-radius: var(--border-radius-small);
    transition: all 0.15s ease;
    
    &:hover {
      color: var(--s-600);
      background-color: var(--s-100);
    }
  }
  
  &__visual {
    display: flex;
    align-items: center;
    gap: var(--space-normal);
  }
  
  &__color {
    display: flex;
    align-items: center;
  }
  
  &__color-badge {
    display: block;
    width: 28px;
    height: 28px;
    border-radius: var(--border-radius-normal);
    border: 2px solid var(--white);
    box-shadow: var(--shadow-small);
  }
  
  &__icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    border-radius: var(--border-radius-normal);
    background-color: var(--s-100);
    color: var(--s-600);
  }
  
  &__info {
    flex: 1;
    min-width: 200px;
    
    h4 {
      margin: 0 0 var(--space-micro);
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
      line-height: 1.4;
    }
    
    p {
      margin: 0;
      font-size: var(--font-size-small);
      color: var(--s-600);
      font-family: 'Monaco', 'Menlo', monospace;
      background-color: var(--s-50);
      padding: 2px 6px;
      border-radius: var(--border-radius-small);
      display: inline-block;
    }
  }
  
  &__stats {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--space-micro);
    min-width: 80px;
    
    .stage-item__count {
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
      background-color: var(--s-100);
      padding: var(--space-small) var(--space-normal);
      border-radius: var(--border-radius-normal);
      min-width: 40px;
      text-align: center;
    }
    
    .stage-item__count-label {
      font-size: var(--font-size-mini);
      color: var(--s-600);
      text-align: center;
    }
  }
  
  &__status {
    min-width: 60px;
    display: flex;
    justify-content: center;
  }
  
  &__actions {
    display: flex;
    gap: var(--space-small);
    min-width: 80px;
    justify-content: flex-end;
  }
}

// Responsive design
@media (max-width: 1024px) {
  .stage-item {
    gap: var(--space-normal);
    
    &__info {
      min-width: 150px;
    }
    
    &__stats {
      min-width: 60px;
    }
  }
}

@media (max-width: 768px) {
  .stage-item {
    flex-direction: column;
    gap: var(--space-normal);
    padding: var(--space-normal);
    
    &__visual,
    &__info,
    &__stats,
    &__status,
    &__actions {
      width: 100%;
      min-width: auto;
    }
    
    &__info {
      text-align: center;
    }
    
    &__stats {
      flex-direction: row;
      justify-content: center;
      
      .stage-item__count {
        margin-right: var(--space-small);
      }
    }
    
    &__actions {
      justify-content: center;
    }
  }
}
</style>