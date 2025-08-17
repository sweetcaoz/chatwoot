import { frontendURL } from '../../../helper/URLHelper';
import { FEATURE_FLAGS } from '../../../featureFlags';

const KanbanLayout = () => import('./Index.vue');
const KanbanBoard = () => import('./Board.vue');
const KanbanStageManager = () => import('./StageManager.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/kanban'),
    component: KanbanLayout,
    name: 'kanban_layout',
    meta: {
      permissions: ['administrator', 'agent'],
      featureFlag: FEATURE_FLAGS.KANBAN,
    },
    children: [
      {
        path: '',
        redirect: 'board',
      },
      {
        path: 'board',
        name: 'kanban_board',
        component: KanbanBoard,
        meta: {
          permissions: ['administrator', 'agent'],
          featureFlag: FEATURE_FLAGS.KANBAN,
        },
      },
      {
        path: 'stages',
        name: 'kanban_stages',
        component: KanbanStageManager,
        meta: {
          permissions: ['administrator'],
          featureFlag: FEATURE_FLAGS.KANBAN,
        },
      },
    ],
  },
];

export default {
  routes,
};