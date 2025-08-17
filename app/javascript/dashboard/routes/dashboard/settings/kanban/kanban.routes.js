import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/kanban'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'kanban_settings_wrapper',
          meta: {
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'kanban_settings_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'kanban_settings_list',
          meta: {
            featureFlag: FEATURE_FLAGS.KANBAN,
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};