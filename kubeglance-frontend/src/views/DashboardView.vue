<template>
  <div class="space-y-6 p-12">
    
    <LoadingOverlay :show="isLoading && hasNamespaceChanged" message="Refreshing cluster data..." />
    
    <div class="flex flex-col space-y-4 md:space-y-0 md:flex-row md:items-center md:justify-between">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold tracking-tight text-card-foreground">
          Cluster Overview ({{ currentClusterContext.name }})
        </h1>
        <div class="flex items-center text-sm text-muted-foreground">

            <ServerStackIcon class="size-6 text-primary mr-1" />
          <span class="ml-1">{{ currentClusterContext.server }}</span>
        </div>
      </div>
      
      <!-- Controls: Namespace Selector, Refresh Options, Connection Status -->
      <div class="flex flex-col space-y-3 md:space-y-0 md:flex-row md:items-center md:space-x-4">
        <!-- Namespace Selector -->
        <div class="flex items-center">
          <label for="namespace-selector" class="mr-2 text-sm font-medium text-card-foreground">Namespace:</label>
          <select 
            id="namespace-selector" 
            v-model="selectedNamespace" 
            @change="handleNamespaceChange"
            class="bg-card text-card-foreground px-3 py-1.5 rounded-md border border-border focus:outline-none focus:ring-2 focus:ring-primary/50"
          >
            <option value="all">All Namespaces</option>
            <option v-for="ns in namespaces" :key="ns.name" :value="ns.name">{{ ns.name }}</option>
          </select>
        </div>
        
        <!-- Refresh Controls -->
        <div class="flex items-center space-x-3">
          <!-- Auto-refresh toggle -->
          <div class="flex items-center space-x-2">
            <label for="auto-refresh" class="text-sm font-medium text-card-foreground">Auto-refresh:</label>
            <input 
              id="auto-refresh" 
              type="checkbox" 
              v-model="autoRefreshEnabled"
              class="h-4 w-4 rounded border-border text-primary focus:ring-primary/50"
            />
          </div>
          
          <!-- Refresh interval selector -->
          <div class="flex items-center space-x-2" v-if="autoRefreshEnabled">
            <select 
              v-model="refreshInterval" 
              @change="restartRefreshTimer"
              class="bg-card text-card-foreground px-2 py-1 text-sm rounded-md border border-border focus:outline-none focus:ring-2 focus:ring-primary/50"
            >
              <option :value="10000">10s</option>
              <option :value="30000">30s</option>
              <option :value="60000">1m</option>
              <option :value="300000">5m</option>
            </select>
          </div>
          
          <!-- Manual refresh button -->
          <button 
            @click="refreshData" 
            class="inline-flex items-center space-x-1 px-3 py-1.5 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-colors"
            :disabled="isLoading"
          >
            <svg 
              class="w-4 h-4"
              :class="{ 'animate-spin': isLoading }"
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24" 
              xmlns="http://www.w3.org/2000/svg"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
            </svg>
            <span>{{ isLoading ? 'Refreshing...' : 'Refresh' }}</span>
          </button>
        </div>
        
        <!-- Connection Status -->
        <div class="flex items-center space-x-2 px-3 py-1 bg-success/20 rounded-full">
          <span class="h-2.5 w-2.5 rounded-full bg-success animate-pulse"></span>
          <span class="text-sm font-medium text-success">Connected</span>
        </div>
        
        <!-- Disconnect Button -->
        <button 
          @click="handleDisconnect" 
          class="inline-flex items-center space-x-2 px-3 py-1.5 bg-destructive text-destructive-foreground rounded-md hover:bg-destructive/90 focus:outline-none focus:ring-2 focus:ring-destructive/50 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          <span>Disconnect</span>
        </button>
      </div>
    </div>
    
    <!-- Last refreshed indicator -->
    <div class="text-sm text-muted-foreground">
      Last refreshed: {{ lastRefreshed }}
      <span v-if="autoRefreshEnabled" class="ml-2">
        (Next refresh in {{ nextRefreshCountdown }}s)
      </span>
    </div>
    

    <!-- Resource Grid - Single Row -->
    <div class="grid grid-cols-1 gap-6">
      <DeploymentsSection 
        :deployments="filteredDeployments"
      />
      
      <ServicesSection 
        :services="filteredServices"
      />
      
      <PodsSection 
        :pods="filteredPods"
      />
    </div>

    <!-- Resource Usage Chart -->
    <ResourceUsageChart
      :title="selectedNamespace === 'all' ? 'Cluster Resources' : `Resources`"
    />

    <!-- Recent Activity Section -->
    <RecentActivitySection
      :activities="recentActivities"
      :selectedNamespace="selectedNamespace"
    />



    <!-- Stats Cards -->
    <div class="grid grid-cols-1 gap-6">
      <NamespacesSection 
        :namespaces="namespaces"
      />
      
      <SecretsSection 
        :secrets="secrets"
      />
      
      <ConfigMapsSection 
        :configMaps="configMaps"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch, onBeforeUnmount } from 'vue';
import apiService from '../services/apiService.js';
import { formatDate, formatAge } from '../helper/formatters.js'
import { getActivityTypeColor } from '../helper/utils.js'
import LoadingOverlay from '../components/LoadingOverlay.vue'; 
import ResourceSection from '../components/ResourceSection.vue';
import DeploymentsSection from '../components/resources/DeploymentsSection.vue';
import ServicesSection from '../components/resources/ServicesSection.vue';
import PodsSection from '../components/resources/PodsSection.vue';
import ResourceUsageChart from '../components/ResourceUsageChart.vue';
import NamespacesSection from '../components/resources/NamespacesSection.vue';
import SecretsSection from '../components/resources/SecretsSection.vue';
import ConfigMapsSection from '../components/resources/ConfigMapsSection.vue';
import RecentActivitySection from '../components/RecentActivitySection.vue';
import { ServerStackIcon } from '@heroicons/vue/24/outline';
import { useRouter } from 'vue-router';


const namespaces = ref([]);
const pods = ref([]);
const deployments = ref([]);
const services = ref([]);
const isLoading = ref(false);
const error = ref(null);
const resourceUsage = ref({ cpu: 48, memory: 62 }); 
const selectedNamespace = ref('default'); 
const expandedSections = ref({
  deployments: false,
  services: false,
  pods: false
});
const selectedActivityType = ref('all');
const router = useRouter();

const autoRefreshEnabled = ref(true);
const refreshInterval = ref(60000);
const refreshTimer = ref(null);
const lastRefreshed = ref('Never');
const nextRefreshCountdown = ref(60);
const countdownTimer = ref(null);

const hasNamespaceChanged = ref(false);

const currentClusterContext = ref({});

const recentActivities = ref([]);

const filteredPods = computed(() => pods.value);
const filteredDeployments = computed(() => deployments.value);
const filteredServices = computed(() => services.value);

// Filter activities by namespace and type
const filteredActivities = computed(() => {
  let filtered = recentActivities.value;
  
  // Filter by namespace first
  if (selectedNamespace.value !== 'all') {
    filtered = filtered.filter(activity => activity.namespace === selectedNamespace.value);
  }
  
  // Then filter by activity type if needed
  if (selectedActivityType.value !== 'all') {
    filtered = filtered.filter(activity => activity.type === selectedActivityType.value);
  }
  
  return filtered;
});

// Filtered resource usage based on selected namespace
const filteredResourceUsage = computed(() => {
  if (selectedNamespace.value === 'all') {
    return resourceUsage.value;
  }
  
  // Find the namespace in our stats
  const ns = namespaces.value.find(ns => ns.name === selectedNamespace.value);
  if (!ns) return { cpu: 0, memory: 0 };
  
  // Extract CPU percentage from string format (e.g. '120m' to 12%)
  const cpuValue = parseInt(ns.cpu) || 0;
  const cpuPercentage = Math.min(Math.round((cpuValue / 1000) * 100), 100);
  
  // Extract memory percentage from string format (e.g. '256Mi' to 25%)
  const memoryValue = parseInt(ns.memory) || 0;
  const memoryPercentage = Math.min(Math.round((memoryValue / 1024) * 100), 100);
  
  return {
    cpu: cpuPercentage,
    memory: memoryPercentage
  };
});

const filteredStats = computed(() => {
  return {
    pods: {
      total: filteredPods.value.length,
      running: filteredPods.value.filter(pod => pod.status === 'Running').length
    },
    deployments: {
      total: filteredDeployments.value.length,
      available: filteredDeployments.value.filter(dep => dep.replicas?.desired === dep.replicas?.available).length
    },
    services: {
      total: filteredServices.value.length
    }
  };
});

// Format the current time for the "last refreshed" display
const formatRefreshTime = () => {
  const now = new Date();
  const hours = now.getHours().toString().padStart(2, '0');
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const seconds = now.getSeconds().toString().padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
};

const handleNamespaceChange = async () => {
  hasNamespaceChanged.value = true;
  await refreshData();
  hasNamespaceChanged.value = false;
};

// Refresh countdown timer function
const startCountdownTimer = () => {
  // Clear any existing countdown
  if (countdownTimer.value) {
    clearInterval(countdownTimer.value);
  }
  
  // Set initial countdown value
  nextRefreshCountdown.value = Math.floor(refreshInterval.value / 1000);
  
  // Start countdown timer
  countdownTimer.value = setInterval(() => {
    if (nextRefreshCountdown.value > 0) {
      nextRefreshCountdown.value--;
    }
  }, 1000);
};

const refreshData = async () => {  
  isLoading.value = true;
  error.value = null;

  try {
    // Always fetch namespaces list (needed for namespace selector)
    const nsData = await apiService.getNamespaces();
    namespaces.value = nsData;
    
    // Fetch resources only for the selected namespace
    const [
      podData,
      deploymentData,
      serviceData,
      eventData,
      secretData,
      configMapData
    ] = await Promise.all([
      apiService.getPods(selectedNamespace.value),
      apiService.getDeployments(selectedNamespace.value),
      apiService.getServices(selectedNamespace.value),
      apiService.getRecentEvents(selectedNamespace.value),
      apiService.getSecrets(selectedNamespace.value),
      apiService.getConfigMaps(selectedNamespace.value)
    ]);

    pods.value = podData;
    deployments.value = deploymentData;
    services.value = serviceData;
    recentActivities.value = eventData;
    secrets.value = secretData;
    configMaps.value = configMapData;

    // Update refresh time information
    lastRefreshed.value = formatRefreshTime();
    
    // Add a refresh notification to the activity log
    recentActivities.value.unshift({
      type: 'Info',
      message: `Dashboard refreshed for namespace: ${selectedNamespace.value}`,
      timestamp: new Date(),
      namespace: selectedNamespace.value
    });
    
    // Keep activity log from growing too large
    if (recentActivities.value.length > 10) {
      recentActivities.value.pop();
    }
    
    // Reset the countdown if auto-refresh is enabled
    if (autoRefreshEnabled.value) {
      startCountdownTimer();
    }
    
  } catch (err) {
    console.error('Error refreshing cluster data:', err);
    error.value = err.message || 'Failed to refresh cluster data';
    
    // Add error to activity log
    recentActivities.value.unshift({
      type: 'Warning',
      message: `Failed to refresh: ${error.value}`,
      timestamp: new Date(),
      namespace: selectedNamespace.value
    });
  } finally {
    isLoading.value = false;
  }
};

// Start or restart the auto-refresh timer
const restartRefreshTimer = () => {
  if (refreshTimer.value) {
    clearInterval(refreshTimer.value);
    refreshTimer.value = null;
  }
  
  if (autoRefreshEnabled.value) {
    startCountdownTimer();
    refreshTimer.value = setInterval(refreshData, refreshInterval.value);
  }
};

// Watch for changes to autoRefreshEnabled
watch(autoRefreshEnabled, (newValue) => {
  if (newValue) {
    // Start the timer if auto-refresh was enabled
    restartRefreshTimer();
  } else {
    // Stop the timer if auto-refresh was disabled
    if (refreshTimer.value) {
      clearInterval(refreshTimer.value);
      refreshTimer.value = null;
    }
    
    // Also clear the countdown timer
    if (countdownTimer.value) {
      clearInterval(countdownTimer.value);
      countdownTimer.value = null;
    }
  }
});

// Watch for changes to refreshInterval
watch(refreshInterval, () => {
  // Restart the timer with the new interval
  if (autoRefreshEnabled.value) {
    restartRefreshTimer();
  }
});

// Clean up timers when component is destroyed
onBeforeUnmount(() => {
  if (refreshTimer.value) {
    clearInterval(refreshTimer.value);
  }
  
  if (countdownTimer.value) {
    clearInterval(countdownTimer.value);
  }
});

// Load data on component mount
onMounted(async () => {

  // Fetch initial data
  currentClusterContext.value = await apiService.getCurrentContext();
  
  refreshData();  
  // Start auto-refresh if enabled
  if (autoRefreshEnabled.value) {
    restartRefreshTimer();
  }
});

// Add a new function to toggle sections individually
const toggleSection = (section) => {
  expandedSections.value[section] = !expandedSections.value[section];
};

// Add new refs for the resources
const secrets = ref([]);
const configMaps = ref([]);

// Add computed properties for filtering
const filteredSecrets = computed(() => secrets.value);
const filteredConfigMaps = computed(() => configMaps.value);

const handleDisconnect = async () => {
  try {
    await apiService.disconnectCluster();
    router.push('/kubeconfig');
  } catch (error) {
    console.error('Failed to disconnect:', error);
  }
};

</script>