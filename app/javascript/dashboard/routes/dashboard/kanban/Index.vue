<template>
  <div class="kanban-layout">
    <div class="kanban-header">
      <div class="kanban-header__title">
        <h2 class="kanban-title">{{ $t('KANBAN.TITLE') }}</h2>
        <p class="kanban-subtitle">{{ $t('KANBAN.SUBTITLE') }}</p>
      </div>
      <div class="kanban-header__actions">
        <router-link
          v-if="isAdmin"
          :to="{ name: 'kanban_stages' }"
          class="kanban-settings-link"
        >
          <fluent-icon icon="settings" size="16" />
          {{ $t('KANBAN.MANAGE_STAGES') }}
        </router-link>
      </div>
    </div>
    <router-view />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

export default {
  name: 'KanbanLayout',
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentRole: 'getCurrentRole',
    }),
    isAdmin() {
      return this.currentRole === 'administrator';
    },
  },
};
</script>

<style scoped lang="scss">
.kanban-layout {
  display: flex;
  flex-direction: column;
  height: 100%;
  background-color: var(--s-50);
}

.kanban-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-normal) var(--space-large);
  background-color: var(--white);
  border-bottom: 1px solid var(--s-100);

  &__title {
    .kanban-title {
      margin: 0;
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
    }

    .kanban-subtitle {
      margin: var(--space-micro) 0 0;
      font-size: var(--font-size-small);
      color: var(--s-600);
    }
  }

  &__actions {
    .kanban-settings-link {
      display: inline-flex;
      align-items: center;
      gap: var(--space-micro);
      padding: var(--space-small) var(--space-normal);
      border-radius: var(--border-radius-normal);
      background-color: var(--s-50);
      color: var(--s-700);
      text-decoration: none;
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
      transition: all 0.2s ease;

      &:hover {
        background-color: var(--s-100);
        color: var(--s-900);
      }
    }
  }
}
</style>