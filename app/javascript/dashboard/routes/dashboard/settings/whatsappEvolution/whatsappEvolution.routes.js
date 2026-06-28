import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import WhatsappEvolutionHome from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/whatsapp-evolution'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'whatsapp_evolution_index',
          meta: {
            permissions: ['administrator'],
          },
          component: WhatsappEvolutionHome,
        },
      ],
    },
  ],
};
