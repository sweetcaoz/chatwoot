<template>
  <div class="kanban-board">
    <div v-if="isLoading" class="kanban-loading">
      <spinner />
      <p>{{ $t('KANBAN.LOADING') }}</p>
    </div>
    
    <div v-else-if="!stages.length" class="kanban-empty">
      <fluent-icon icon="view-dashboard" size="48" />
      <h3>{{ $t('KANBAN.NO_STAGES') }}</h3>
      <p>{{ $t('KANBAN.NO_STAGES_DESCRIPTION') }}</p>
      <woot-button
        v-if="isAdmin"
        color-scheme="primary"
        @click="$router.push({ name: 'kanban_stages' })"
      >
        {{ $t('KANBAN.CREATE_STAGES') }}
      </woot-button>
    </div>
    
    <div v-else class="kanban-board__container">
      <div class="kanban-board__columns">
        <KanbanColumn
          v-for="stage in stages"
          :key="stage.key"
          :stage="stage"
          :conversations="getConversationsByStage(stage.key)"
          :is-moving="isMoving"
          @drop="handleDrop"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import KanbanColumn from './components/KanbanColumn.vue';

export default {
  name: 'KanbanBoard',
  components: {
    Spinner,
    KanbanColumn,
  },
  data() {
    return {
      boardKey: 'sales',
    };
  },
  computed: {
    ...mapGetters({
      currentRole: 'getCurrentRole',
    }),
    ...mapGetters('kanban', {
      stages: 'getActiveStages',
      getConversationsByStage: 'getConversationsByStage',
      isLoading: 'isLoading',
      isMoving: 'isMoving',
    }),
    isAdmin() {
      return this.currentRole === 'administrator';
    },
  },
  mounted() {
    this.fetchBoard(this.boardKey);
    this.subscribeToKanbanUpdates();
  },
  methods: {
    ...mapActions('kanban', [
      'fetchBoard',
      'moveConversation',
      'subscribeToKanbanUpdates',
    ]),
    
    async handleDrop({ conversationId, fromStage, toStage, position }) {
      try {
        await this.moveConversation({
          conversationId,
          fromStage,
          toStage,
          position,
        });
      } catch (error) {
        this.$store.dispatch('showAlert', {
          message: this.$t('KANBAN.MOVE_ERROR'),
        });
      }
    },
  },
};
</script>

<style scoped lang="scss">
.kanban-board {
  flex: 1;
  overflow: hidden;
  position: relative;

  &__container {
    height: 100%;
    overflow-x: auto;
    overflow-y: hidden;
    padding: var(--space-normal);
  }

  &__columns {
    display: flex;
    gap: var(--space-normal);
    height: 100%;
    min-width: max-content;
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
  gap: var(--space-normal);
  text-align: center;
  padding: var(--space-large);
  
  h3 {
    margin: 0;
    font-size: var(--font-size-large);
    color: var(--s-800);
  }
  
  p {
    margin: 0;
    color: var(--s-600);
    max-width: 400px;
  }
  
  .button {
    margin-top: var(--space-normal);
  }
}
</style>