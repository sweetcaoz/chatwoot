import { frontendURL } from '../../../helper/URLHelper';

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
        },
      },
      {
        path: 'stages',
        name: 'kanban_stages',
        component: KanbanStageManager,
        meta: {
          permissions: ['administrator'],
        },
      },
    ],
  },
];

export default {
  routes,
};