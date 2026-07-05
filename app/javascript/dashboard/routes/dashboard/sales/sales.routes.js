import { frontendURL } from '../../../helper/URLHelper';
import SettingsWrapper from '../settings/SettingsWrapper.vue';
import Products from './Products.vue';
import Orders from './Orders.vue';
import SalesReports from './SalesReports.vue';
import NexusIntegration from './NexusIntegration.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/sales'),
      component: SettingsWrapper,
      children: [
        {
          path: 'products',
          name: 'nexus_sales_products',
          meta: { permissions: ['administrator', 'agent'] },
          component: Products,
        },
        {
          path: 'orders',
          name: 'nexus_sales_orders',
          meta: { permissions: ['administrator', 'agent'] },
          component: Orders,
        },
        {
          path: 'reports',
          name: 'nexus_sales_reports',
          meta: { permissions: ['administrator', 'agent'] },
          component: SalesReports,
        },
        {
          path: 'integration',
          name: 'nexus_integration',
          meta: { permissions: ['administrator'] },
          component: NexusIntegration,
        },
        {
          path: '',
          redirect: { name: 'nexus_sales_products' },
        },
      ],
    },
  ],
};
