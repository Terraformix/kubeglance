<template>
  <div class="bg-card rounded-lg shadow-md hover:shadow-lg transition-shadow border border-border overflow-hidden">
    <div class="p-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-semibold text-card-foreground">
          {{ selectedNamespace === 'all' ? 'Recent Activity' : `Recent Activity (${selectedNamespace})` }}
        </h2>
        
        <div class="flex items-center space-x-4">
          <!-- Activity Type Filter -->
          <div class="flex items-center">
            <label for="activity-type-filter" class="mr-2 text-sm font-medium text-card-foreground">Show:</label>
            <select
              id="activity-type-filter"
              v-model="selectedActivityType"
              class="bg-card text-card-foreground px-3 py-1.5 rounded-md border border-border focus:outline-none focus:ring-2 focus:ring-primary/50"
            >
              <option value="all">All Activities</option>
              <option value="Normal">Success</option>
              <option value="Warning">Warning</option>
              <option value="Info">Info</option>
            </select>
          </div>
          
          <!-- Expand/Collapse Button -->
          <button @click="isExpanded = !isExpanded" class="text-muted-foreground hover:text-card-foreground">
            <ChevronUpIcon v-if="isExpanded" class="w-6 h-6"/>
            <ChevronDownIcon v-else class="w-6 h-6"/>
          </button>
        </div>
      </div>
      
      <!-- Resource Summary -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div class="bg-card-muted rounded-lg p-4">
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-muted-foreground">Activity Count</span>
            <span class="text-xl font-bold text-card-foreground">{{ filteredActivities.length }}</span>
          </div>
        </div>
        <div class="bg-card-muted rounded-lg p-4">
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-muted-foreground">Warnings</span>
            <span class="text-xl font-bold text-destructive">
              {{ activities.filter(a => a.type === 'Warning').length }}
            </span>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Expanded Content -->
    <div v-if="isExpanded" class="border-t border-border">
      <div class="p-4 bg-card-muted">
        <div class="space-y-4">
          <!-- Search Filter -->
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div class="relative flex-1">
              <input
                type="text"
                v-model="searchQuery"
                @input="onSearchInput"
                placeholder="Search activities..."
                class="w-full pl-10 pr-10 py-2 bg-card border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
              <svg class="absolute left-3 top-2.5 w-5 h-5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="absolute right-3 top-2.5 text-muted-foreground hover:text-card-foreground"
                title="Clear search"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
          
          <!-- Activity List -->
          <div v-if="displayedActivities.length > 0" class="space-y-4">
            <div
              v-for="(activity, index) in displayedActivities"
              :key="index"
              class="flex items-start space-x-3 p-3 rounded-md hover:bg-card-hover transition-colors"
            >
              <div
                :class="`bg-${getActivityTypeColor(activity.type)}/20 text-${getActivityTypeColor(activity.type)}`"
                class="p-1.5 rounded-full flex-shrink-0"
              >
                <!-- Normal/Success Icon -->
                <CheckIcon
                  v-if="activity.type === 'Normal'"
                  class="w-6 h-6"
                />
                <!-- Warning Icon -->
                <ExclamationCircleIcon
                  v-else-if="activity.type === 'Warning'"
                  class="w-6 h-6"
                />
                <!-- Info Icon -->
                <InformationCircleIcon
                  v-else
                  class="w-6 h-6"
                />
              </div>
              <div>
                <div class="font-medium text-card-foreground">{{ activity.message }}</div>
                <div class="text-sm text-muted-foreground">{{ formatDate(activity.timestamp) }}</div>
                <div class="text-sm text-muted-foreground">
                  <span :class="`text-${getActivityTypeColor(activity.type)}`">{{ activity.type }}</span> •
                  {{ activity.namespace }}
                  <template v-if="activity.type !== 'Info'">
                    • {{ activity.involvedObject?.name }} ({{ activity.involvedObject?.kind }}) •
                    {{ activity.reason }}
                  </template>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Empty State -->
          <div v-else class="text-center py-6 text-muted-foreground">
            No matching activity to show
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { formatDate } from '../helper/formatters';
import { getActivityTypeColor } from '../helper/utils';
import {
  CheckIcon,
  ExclamationCircleIcon,
  InformationCircleIcon,
  ChevronDownIcon,
  ChevronUpIcon
} from '@heroicons/vue/24/outline';

const props = defineProps({
  activities: {
    type: Array,
    required: true,
    default: () => []
  },
  selectedNamespace: {
    type: String,
    default: 'all'
  }
});

// State management
const isExpanded = ref(true); // Default to expanded
const selectedActivityType = ref('all');
const searchQuery = ref('');

// Filter activities by type
const filteredActivities = computed(() => {
  let filtered = props.activities;
  
  // Filter by activity type if needed
  if (selectedActivityType.value !== 'all') {
    filtered = filtered.filter(activity => activity.type === selectedActivityType.value);
  }
  
  return filtered;
});

// Further filter by search term
const displayedActivities = computed(() => {
  if (!searchQuery.value) return filteredActivities.value;
  
  const query = searchQuery.value.toLowerCase();
  return filteredActivities.value.filter(activity => 
    activity.message.toLowerCase().includes(query) ||
    activity.namespace.toLowerCase().includes(query) ||
    activity.type.toLowerCase().includes(query) ||
    (activity.reason && activity.reason.toLowerCase().includes(query)) ||
    (activity.involvedObject?.name && activity.involvedObject.name.toLowerCase().includes(query)) ||
    (activity.involvedObject?.kind && activity.involvedObject.kind.toLowerCase().includes(query))
  );
});

// Handle search
const onSearchInput = () => {
  // Additional logic if needed
};

// Clear search
const clearSearch = () => {
  searchQuery.value = '';
};

// Ensure it's expanded by default
onMounted(() => {
  isExpanded.value = true;
});
</script>