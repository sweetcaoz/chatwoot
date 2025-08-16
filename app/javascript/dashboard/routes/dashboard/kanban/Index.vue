<template>
  <div class="kanban-layout">
    <div class="kanban-header">
      <div class="kanban-header__title">
        <h2 class="kanban-title">{{ $t('KANBAN.TITLE') }}</h2>
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
  height: 100vh;
  background-color: var(--s-25);
}

.kanban-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-large) var(--space-mega);
  background-color: var(--white);
  border-bottom: 1px solid var(--s-100);
  box-shadow: var(--shadow-small);

  &__title {
    .kanban-title {
      margin: 0;
      font-size: var(--font-size-mega);
      font-weight: var(--font-weight-bold);
      color: var(--s-900);
      letter-spacing: -0.02em;
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
      gap: var(--space-small);
      padding: var(--space-normal) var(--space-large);
      border-radius: var(--border-radius-normal);
      background-color: var(--w-500);
      color: var(--white);
      text-decoration: none;
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-medium);
      transition: all 0.2s ease;
      box-shadow: var(--shadow-small);

      &:hover {
        background-color: var(--w-600);
        transform: translateY(-1px);
        box-shadow: var(--shadow-medium);
      }
    }
  }
}
</style>