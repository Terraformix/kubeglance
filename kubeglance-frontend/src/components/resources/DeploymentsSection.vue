<template>

  <ResourceSection 
    title="Deployments" 
    :count="filteredDeployments.length"
    :isEmpty="filteredDeployments.length === 0"
    @search="onSearch"
  >

        
        <template #summary>
        <div class="flex items-center justify-start space-x-4">
            <div class="text-3xl font-bold text-card-foreground">{{ stats.available }} / {{ stats.total }}</div>
            <div :class="stats.running === stats.total ? 'text-success' : 'text-warning'" class="flex items-center">
            <div :class="`flex items-center space-x-1 px-3 py-1 bg-${stats.available === stats.total ? 'success' : 'warning'}/20 rounded-full`">
                <span :class="`text-sm font-medium text-${stats.available === stats.total ? 'success' : 'warning'}`">
                {{ stats.available === stats.total ? 'Healthy' : 'Warning' }}
                </span>
            </div>
            </div>
        </div>
        </template>

    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Ready</th>
      <th class="pb-2 font-medium text-card-foreground">Up-to-date</th>
      <th class="pb-2 font-medium text-card-foreground">Available</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
      <th class="pb-2 font-medium text-card-foreground">Namespace</th>
    </template>
    
    <template #items>
      <tr v-for="deployment in filteredDeployments" :key="deployment.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground" :title="deployment.name">{{ truncateText(deployment.name) }}</td>
        <td class="py-2 text-card-foreground">{{ deployment.replicas?.ready || 0 }}/{{ deployment.replicas?.desired || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ deployment.replicas?.upToDate || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ deployment.replicas?.available || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ formatAge(deployment.creationTimestamp) }}</td>
        <td class="py-2 text-card-foreground">{{ deployment.namespace }}</td>
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
  deployments: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredDeployments = computed(() => {

  if (!searchQuery.value) return props.deployments;
  
  const query = searchQuery.value.toLowerCase();
    return props.deployments.filter(deployment => deployment.name.toLowerCase().includes(query) || deployment.namespace?.toLowerCase().includes(query)
  );
});

const stats = computed(() => ({
  total: filteredDeployments.value.length,
  available: filteredDeployments.value.filter(dep => dep.replicas?.desired === dep.replicas?.available).length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};
</script> 