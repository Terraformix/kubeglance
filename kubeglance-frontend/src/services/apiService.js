import axios from 'axios';
import router from '../router';

const api = axios.create({
  baseURL: "/api",
  headers: { 'Content-Type': 'application/json' },
});

let currentUserId = localStorage.getItem('userId') || '';

const handleApiError = (error, message) => {
  const errorMessage = error.response?.data?.error || error.message || message;
  console.error(message, error);
  throw error;
};

const makeApiCall = async (method, endpoint, data = null, config = {}) => {
  try {
    const response = await api({
      method,
      url: endpoint,
      data: method === 'delete' ? undefined : data,  // Avoid sending data for DELETE
      ...config
    });
    return response.data;
  } catch (error) {
    console.error(error);
    return handleApiError(error, `Error making ${method.toUpperCase()} request to ${endpoint}`);
  }
};


const apiService = {
  uploadKubeconfig: async (file) => {
    const formData = new FormData();
    formData.append('kubeconfig', file);

    try {
      const response = await makeApiCall('post', '/kubeconfig', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      currentUserId = response.userId;
      localStorage.setItem('userId', currentUserId);
      return response;
    } catch (error) {
      handleApiError(error, 'Error uploading kubeconfig');
    }
  },

  checkKubeconfigExists: async () => {
    const userId = localStorage.getItem('userId');
    if (!userId) {
      return false;
    }
  
    try {
      const response = await makeApiCall('get', `/kubeconfig?userId=${userId}`);

      if (!response.exists) {
        localStorage.removeItem('userId');
        return false;
      } else {
        return true;
      }
    } catch (error) {
      localStorage.removeItem('userId');
      return false;
    }
  },

  getNamespaces: async (includePodCount = true) =>
    makeApiCall('get', `/namespaces?userId=${currentUserId}&includePodCount=${includePodCount}`),

  getCurrentContext: async () =>
    makeApiCall('get', `/context?userId=${currentUserId}`),

  getRecentEvents: async (namespace = '', limit = 50) =>
    makeApiCall('get', `/events?userId=${currentUserId}&namespace=${namespace}&limit=${limit}`),

  getPods: async (namespace = '') =>
    makeApiCall('get', `/pods?userId=${currentUserId}&namespace=${namespace}`),

  getDeployments: async (namespace = '') =>
    makeApiCall('get', `/deployments?userId=${currentUserId}&namespace=${namespace}`),

  getServices: async (namespace = '') =>
    makeApiCall('get', `/services?userId=${currentUserId}&namespace=${namespace}`),

  createNamespace: async (namespaceName) =>
    makeApiCall('post', '/namespaces', { userId: currentUserId, namespaceName }),

  getUserId: () => currentUserId,

  isAuthenticated: () => Boolean(currentUserId),

  getResourceMetrics: async (namespace = '') =>
    makeApiCall('get', `/metrics?userId=${currentUserId}&namespace=${namespace}`),

  getSecrets: async (namespace = '') =>
    makeApiCall('get', `/secrets?userId=${currentUserId}&namespace=${namespace}`),

  getConfigMaps: async (namespace = '') =>
    makeApiCall('get', `/configmaps?userId=${currentUserId}&namespace=${namespace}`),

  deleteKubeconfig: async () => {
    try {

      await makeApiCall('delete', `/kubeconfig?userId=${currentUserId}`);
    } catch (error) {
      console.warn('Failed to delete kubeconfig on server, clearing locally.');
    } finally {
      currentUserId = '';
      localStorage.removeItem('userId');
      localStorage.removeItem('selectedNamespace');
      localStorage.removeItem('lastRefresh');
    }

    return { message: 'Kubeconfig and local data cleared successfully' };
  },

  disconnectCluster: async () => {
    try {
      await apiService.deleteKubeconfig();
      return { message: 'Successfully disconnected from cluster' };
    } catch (error) {
      handleApiError(error, 'Error disconnecting from cluster');
    }
  },
};

export default apiService;
