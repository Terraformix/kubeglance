<template>
  <ResourceSection 
    title="Pods" 
    :count="filteredPods.length"
    :isEmpty="filteredPods.length === 0"
    @search="onSearch"
  >
    <template #summary>
      <div class="flex items-center justify-start space-x-4">
        <div class="text-3xl font-bold text-card-foreground">{{ stats.running }} / {{ stats.total }}</div>
        <div :class="stats.running === stats.total ? 'text-success' : 'text-warning'" class="flex items-center">
            <div :class="`flex items-center space-x-1 px-3 py-1 bg-${stats.running === stats.total ? 'success' : 'warning'}/20 rounded-full`">
                <span :class="`text-sm font-medium text-${stats.running === stats.total ? 'success' : 'warning'}`">
                    {{ stats.running === stats.total ? 'Running' : 'Warning' }}
                </span>
            </div>
        </div>
      </div>
    </template>
    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Ready</th>
      <th class="pb-2 font-medium text-card-foreground">Status</th>
      <th class="pb-2 font-medium text-card-foreground">Restarts</th>
      <th class="pb-2 font-medium text-card-foreground">Node</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
      <th class="pb-2 font-medium text-card-foreground">Namespace</th>
    </template>
    
    <template #items>
      <tr v-for="pod in filteredPods" :key="pod.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground" :title="pod.name">{{ truncateText(pod.name) }}</td>
        <td class="py-2 text-card-foreground">{{ pod.ready }} / {{ pod.total }}</td>
        <td class="py-2">
          <span :class="`bg-${getStatusColor(pod.status)}/20 text-${getStatusColor(pod.status)} px-2 py-0.5 rounded-full text-xs font-medium`">
            {{ pod.status }}
          </span>
        </td>
        <td class="py-2 text-card-foreground">{{ pod.restarts || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ pod.node || '-' }}</td>
        <td class="py-2 text-card-foreground">{{ formatAge(pod.creationTimestamp) }}</td>
        <td class="py-2 text-card-foreground">{{ pod.namespace }}</td>
      </tr>
    </template>
  </ResourceSection>
</template>

<script setup>
import { computed, ref } from 'vue';
import ResourceSection from '../ResourceSection.vue';
import { formatAge } from "../../helper/formatters.js"
import { truncateText, getStatusColor } from "../../helper/utils.js"

const props = defineProps({
  pods: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredPods = computed(() => {
  if (!searchQuery.value) return props.pods;
  
  const query = searchQuery.value.toLowerCase();
  return props.pods.filter(pod => 
    pod.name.toLowerCase().includes(query) ||
    pod.namespace?.toLowerCase().includes(query) ||
    pod.status?.toLowerCase().includes(query) ||
    pod.node?.toLowerCase().includes(query)
  );
});

const stats = computed(() => ({
  total: filteredPods.value.length,
  running: filteredPods.value.filter(pod => pod.status === 'Running').length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};
</script> 