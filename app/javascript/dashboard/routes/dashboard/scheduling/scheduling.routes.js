import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../settings/SettingsWrapper.vue';
import Services from './Services.vue';
import Appointments from './Appointments.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/scheduling'),
      component: SettingsWrapper,
      children: [
        {
          path: 'appointments',
          name: 'nexus_scheduling_appointments',
          meta: { permissions: ['administrator', 'agent'] },
          component: Appointments,
        },
        {
          path: 'services',
          name: 'nexus_scheduling_services',
          meta: { permissions: ['administrator'] },
          component: Services,
        },
        {
          path: '',
          redirect: { name: 'nexus_scheduling_appointments' },
        },
      ],
    },
  ],
};
