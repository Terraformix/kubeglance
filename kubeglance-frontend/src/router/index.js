import { createRouter, createWebHistory } from 'vue-router';
import DashboardView from '../views/DashboardView.vue';
import KubeconfigView from '../views/KubeconfigView.vue';

import apiService from '../services/apiService.js';

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: DashboardView,
    meta: { requiresKubeconfig: true }
  },
  {
    path: '/kubeconfig',
    name: 'kubeconfig',
    component: KubeconfigView
  }
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

// Navigation guard
router.beforeEach(async (to, from, next) => {
  const userId = localStorage.getItem('userId');

  // If userId is missing, ensure they can only access /kubeconfig
  if (!userId) {
    if (to.path !== '/kubeconfig') {
      return next('/kubeconfig'); // Redirect to upload page
    }
    return next(); // Allow access to /kubeconfig
  }

  // Check kubeconfig only if needed
  const kubeconfigExists = await apiService.checkKubeconfigExists();

  if (!kubeconfigExists) {
    localStorage.removeItem('userId'); // Remove invalid userId
    if (to.path !== '/kubeconfig') {
      return next('/kubeconfig'); // Redirect if kubeconfig is missing
    }
    return next(); // Stay on /kubeconfig
  }

  // Prevent users from going back to /kubeconfig if they already have a valid kubeconfig
  if (to.path === '/kubeconfig') {
    return next('/'); // Redirect them elsewhere (e.g., home/dashboard)
  }

  next(); // Allow navigation
});

export default router;
