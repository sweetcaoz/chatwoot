<template>
  <div class="stage-manager">
    <div class="stage-manager__header">
      <h3>{{ $t('KANBAN.STAGE_MANAGER.TITLE') }}</h3>
      <woot-button
        icon="add"
        color-scheme="success"
        @click="showCreateModal = true"
      >
        {{ $t('KANBAN.STAGE_MANAGER.ADD_STAGE') }}
      </woot-button>
    </div>
    
    <div v-if="isLoading" class="stage-manager__loading">
      <spinner />
    </div>
    
    <div v-else class="stage-manager__content">
      <draggable
        v-model="localStages"
        :animation="200"
        handle=".stage-item__handle"
        class="stage-manager__list"
        @end="handleReorder"
      >
        <template #item="{ element }">
          <div class="stage-item" :key="element.id">
            <div class="stage-item__handle">
              <fluent-icon icon="re-order" size="16" />
            </div>
            
            <div class="stage-item__color">
              <span 
                class="stage-item__color-badge"
                :style="{ backgroundColor: element.color }"
              />
            </div>
            
            <div class="stage-item__icon">
              <fluent-icon :icon="element.icon || 'flag'" size="16" />
            </div>
            
            <div class="stage-item__info">
              <h4>{{ element.name }}</h4>
              <p>{{ $t('KANBAN.STAGE_MANAGER.KEY') }}: {{ element.key }}</p>
            </div>
            
            <div class="stage-item__stats">
              <span class="stage-item__count">
                {{ element.conversations_count }} {{ $t('KANBAN.STAGE_MANAGER.CONVERSATIONS') }}
              </span>
            </div>
            
            <div class="stage-item__status">
              <woot-switch
                v-model="element.active"
                @input="toggleStageStatus(element)"
              />
            </div>
            
            <div class="stage-item__actions">
              <woot-button
                variant="smooth"
                size="tiny"
                icon="edit"
                @click="editStage(element)"
              />
              <woot-button
                variant="smooth"
                size="tiny"
                icon="delete"
                color-scheme="alert"
                @click="confirmDelete(element)"
              />
            </div>
          </div>
        </template>
      </draggable>
    </div>
    
    <!-- Create/Edit Modal -->
    <woot-modal
      :show.sync="showStageModal"
      :on-close="closeStageModal"
    >
      <div class="modal-content">
        <div class="modal-header">
          <h2>{{ editingStage ? $t('KANBAN.STAGE_MANAGER.EDIT_STAGE') : $t('KANBAN.STAGE_MANAGER.CREATE_STAGE') }}</h2>
        </div>
        
        <form @submit.prevent="saveStage" class="stage-form">
          <woot-input
            v-model="stageForm.name"
            :label="$t('KANBAN.STAGE_MANAGER.STAGE_NAME')"
            :placeholder="$t('KANBAN.STAGE_MANAGER.STAGE_NAME_PLACEHOLDER')"
            :error="errors.name"
            required
          />
          
          <woot-input
            v-model="stageForm.key"
            :label="$t('KANBAN.STAGE_MANAGER.STAGE_KEY')"
            :placeholder="$t('KANBAN.STAGE_MANAGER.STAGE_KEY_PLACEHOLDER')"
            :error="errors.key"
            :disabled="!!editingStage"
            required
          />
          
          <div class="form-group">
            <label>{{ $t('KANBAN.STAGE_MANAGER.STAGE_COLOR') }}</label>
            <color-picker
              v-model="stageForm.color"
              :colors="predefinedColors"
            />
          </div>
          
          <woot-input
            v-model="stageForm.icon"
            :label="$t('KANBAN.STAGE_MANAGER.STAGE_ICON')"
            :placeholder="$t('KANBAN.STAGE_MANAGER.STAGE_ICON_PLACEHOLDER')"
          />
          
          <div class="modal-footer">
            <woot-button
              variant="clear"
              @click="closeStageModal"
            >
              {{ $t('COMMON.CANCEL') }}
            </woot-button>
            <woot-button
              :loading="isSaving"
              type="submit"
            >
              {{ editingStage ? $t('COMMON.UPDATE') : $t('COMMON.CREATE') }}
            </woot-button>
          </div>
        </form>
      </div>
    </woot-modal>
    
    <!-- Delete Confirmation Modal -->
    <delete-modal
      :show.sync="showDeleteModal"
      :on-close="closeDeleteModal"
      :on-confirm="deleteStage"
      :title="$t('KANBAN.STAGE_MANAGER.DELETE_TITLE')"
      :message="deleteMessage"
      :confirm-text="$t('COMMON.DELETE')"
      :reject-text="$t('COMMON.CANCEL')"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import draggable from 'vuedraggable';
import Spinner from 'shared/components/Spinner.vue';
import ColorPicker from 'dashboard/components/widgets/ColorPicker.vue';
import DeleteModal from 'dashboard/components/widgets/modal/DeleteModal.vue';

export default {
  name: 'StageManager',
  components: {
    draggable,
    Spinner,
    ColorPicker,
    DeleteModal,
  },
  data() {
    return {
      localStages: [],
      showStageModal: false,
      showDeleteModal: false,
      showCreateModal: false,
      editingStage: null,
      deletingStage: null,
      isSaving: false,
      stageForm: {
        name: '',
        key: '',
        color: '#0EA5E9',
        icon: 'flag',
        board_key: 'sales',
      },
      errors: {},
      predefinedColors: [
        '#0EA5E9', // Blue
        '#8B5CF6', // Purple
        '#F59E0B', // Amber
        '#10B981', // Green
        '#EF4444', // Red
        '#6B7280', // Gray
        '#EC4899', // Pink
        '#14B8A6', // Teal
      ],
    };
  },
  computed: {
    ...mapGetters('kanban', {
      stages: 'getStages',
      isLoading: 'isLoading',
    }),
    deleteMessage() {
      if (!this.deletingStage) return '';
      return this.$t('KANBAN.STAGE_MANAGER.DELETE_MESSAGE', {
        name: this.deletingStage.name,
        count: this.deletingStage.conversations_count,
      });
    },
  },
  watch: {
    stages(newStages) {
      this.localStages = [...newStages];
    },
    showCreateModal(val) {
      if (val) {
        this.showStageModal = true;
        this.editingStage = null;
        this.resetForm();
      }
    },
  },
  mounted() {
    this.fetchStages();
  },
  methods: {
    ...mapActions('kanban', [
      'fetchStages',
      'createStage',
      'updateStage',
      'deleteStage',
      'reorderStages',
    ]),
    
    async handleReorder() {
      const stageIds = this.localStages.map(stage => stage.id);
      try {
        await this.reorderStages(stageIds);
        this.$store.dispatch('showAlert', {
          message: this.$t('KANBAN.STAGE_MANAGER.REORDER_SUCCESS'),
        });
      } catch (error) {
        this.$store.dispatch('showAlert', {
          message: this.$t('KANBAN.STAGE_MANAGER.REORDER_ERROR'),
        });
        // Revert the local changes
        this.localStages = [...this.stages];
      }
    },
    
    editStage(stage) {
      this.editingStage = stage;
      this.stageForm = {
        name: stage.name,
        key: stage.key,
        color: stage.color,
        icon: stage.icon,
        board_key: stage.board_key,
      };
      this.showStageModal = true;
    },
    
    async saveStage() {
      this.errors = {};
      
      // Validate
      if (!this.stageForm.name) {
        this.errors.name = this.$t('KANBAN.STAGE_MANAGER.NAME_REQUIRED');
        return;
      }
      if (!this.stageForm.key) {
        this.errors.key = this.$t('KANBAN.STAGE_MANAGER.KEY_REQUIRED');
        return;
      }
      
      this.isSaving = true;
      try {
        if (this.editingStage) {
          await this.updateStage({
            id: this.editingStage.id,
            ...this.stageForm,
          });
          this.$store.dispatch('showAlert', {
            message: this.$t('KANBAN.STAGE_MANAGER.UPDATE_SUCCESS'),
          });
        } else {
          await this.createStage(this.stageForm);
          this.$store.dispatch('showAlert', {
            message: this.$t('KANBAN.STAGE_MANAGER.CREATE_SUCCESS'),
          });
        }
        this.closeStageModal();
      } catch (error) {
        this.$store.dispatch('showAlert', {
          message: error.message || this.$t('KANBAN.STAGE_MANAGER.SAVE_ERROR'),
        });
      } finally {
        this.isSaving = false;
      }
    },
    
    async toggleStageStatus(stage) {
      try {
        await this.updateStage({
          id: stage.id,
          active: stage.active,
          board_key: stage.board_key,
        });
        this.$store.dispatch('showAlert', {
          message: this.$t('KANBAN.STAGE_MANAGER.STATUS_UPDATED'),
        });
      } catch (error) {
        // Revert the change
        stage.active = !stage.active;
        this.$store.dispatch('showAlert', {
          message: error.message || this.$t('KANBAN.STAGE_MANAGER.STATUS_ERROR'),
        });
      }
    },
    
    confirmDelete(stage) {
      this.deletingStage = stage;
      this.showDeleteModal = true;
    },
    
    async deleteStage() {
      try {
        await this.deleteStage(this.deletingStage.id);
        this.$store.dispatch('showAlert', {
          message: this.$t('KANBAN.STAGE_MANAGER.DELETE_SUCCESS'),
        });
        this.closeDeleteModal();
      } catch (error) {
        this.$store.dispatch('showAlert', {
          message: error.message || this.$t('KANBAN.STAGE_MANAGER.DELETE_ERROR'),
        });
      }
    },
    
    closeStageModal() {
      this.showStageModal = false;
      this.showCreateModal = false;
      this.editingStage = null;
      this.resetForm();
    },
    
    closeDeleteModal() {
      this.showDeleteModal = false;
      this.deletingStage = null;
    },
    
    resetForm() {
      this.stageForm = {
        name: '',
        key: '',
        color: '#0EA5E9',
        icon: 'flag',
        board_key: 'sales',
      };
      this.errors = {};
    },
  },
};
</script>

<style scoped lang="scss">
.stage-manager {
  padding: var(--space-large);
  background-color: var(--white);
  height: 100%;
  overflow-y: auto;
  
  &__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-large);
    
    h3 {
      margin: 0;
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
    }
  }
  
  &__loading {
    display: flex;
    justify-content: center;
    padding: var(--space-mega);
  }
  
  &__list {
    display: flex;
    flex-direction: column;
    gap: var(--space-small);
  }
}

.stage-item {
  display: flex;
  align-items: center;
  gap: var(--space-normal);
  padding: var(--space-normal);
  background-color: var(--s-50);
  border: 1px solid var(--s-200);
  border-radius: var(--border-radius-normal);
  transition: all 0.2s ease;
  
  &:hover {
    background-color: var(--s-75);
    box-shadow: var(--shadow-small);
  }
  
  &__handle {
    cursor: move;
    color: var(--s-500);
    
    &:hover {
      color: var(--s-700);
    }
  }
  
  &__color-badge {
    display: block;
    width: 24px;
    height: 24px;
    border-radius: var(--border-radius-small);
  }
  
  &__icon {
    color: var(--s-600);
  }
  
  &__info {
    flex: 1;
    
    h4 {
      margin: 0 0 var(--space-micro);
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-medium);
      color: var(--s-900);
    }
    
    p {
      margin: 0;
      font-size: var(--font-size-small);
      color: var(--s-600);
    }
  }
  
  &__stats {
    .stage-item__count {
      padding: 4px 8px;
      border-radius: var(--border-radius-small);
      background-color: var(--s-100);
      color: var(--s-700);
      font-size: var(--font-size-small);
    }
  }
  
  &__actions {
    display: flex;
    gap: var(--space-micro);
  }
}

.stage-form {
  .form-group {
    margin-bottom: var(--space-normal);
    
    label {
      display: block;
      margin-bottom: var(--space-small);
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
      color: var(--s-700);
    }
  }
}

.modal-content {
  padding: var(--space-large);
}

.modal-header {
  margin-bottom: var(--space-large);
  
  h2 {
    margin: 0;
    font-size: var(--font-size-large);
    font-weight: var(--font-weight-bold);
    color: var(--s-900);
  }
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-small);
  margin-top: var(--space-large);
  padding-top: var(--space-normal);
  border-top: 1px solid var(--s-100);
}
</style>