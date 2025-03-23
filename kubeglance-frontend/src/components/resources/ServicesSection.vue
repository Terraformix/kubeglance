<template>
  <ResourceSection 
    title="Services" 
    :count="filteredServices.length"
    :isEmpty="filteredServices.length === 0"
    @search="onSearch"
  >

    <template #summary>
      <div class="flex items-center justify-start space-x-4">
        <div class="text-3xl font-bold text-card-foreground">{{ stats.total }} / {{ stats.total }}</div>
        <div :class="stats.total === stats.total ? 'text-success' : 'text-warning'" class="flex items-center">
            <div :class="`flex items-center space-x-1 px-3 py-1 bg-${stats.total === stats.total ? 'success' : 'warning'}/20 rounded-full`">
                <span :class="`text-sm font-medium text-${stats.total === stats.total ? 'success' : 'warning'}`">
                    {{ stats.total === stats.total ? 'Active' : 'Warning' }}
                </span>
            </div>
        </div>
      </div>
    </template>
    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Type</th>
      <th class="pb-2 font-medium text-card-foreground">Cluster IP</th>
      <th class="pb-2 font-medium text-card-foreground">External IP</th>
      <th class="pb-2 font-medium text-card-foreground">Ports</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
      <th class="pb-2 font-medium text-card-foreground">Namespace</th>
    </template>
    
    <template #items>
      <tr v-for="service in filteredServices" :key="service.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground" :title="service.name">{{ truncateText(service.name) }}</td>
        <td class="py-2 text-card-foreground">{{ service.type }}</td>
        <td class="py-2 text-card-foreground">{{ service.clusterIP }}</td>
        <td class="py-2 text-card-foreground">{{ service.externalIPs[0] || '-' }}</td>
        <td class="py-2 text-card-foreground">{{ formatPorts(service.ports) }}</td>
        <td class="py-2 text-card-foreground">{{ formatAge(service.creationTimestamp) }}</td>
        <td class="py-2 text-card-foreground">{{ service.namespace }}</td>
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
  services: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredServices = computed(() => {
  if (!searchQuery.value) return props.services;
  
  const query = searchQuery.value.toLowerCase();
  return props.services.filter(service => 
    service.name.toLowerCase().includes(query) ||
    service.namespace?.toLowerCase().includes(query) ||
    service.type?.toLowerCase().includes(query) ||
    service.clusterIP?.includes(query)
  );
});

const stats = computed(() => ({
  total: filteredServices.value.length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};

const formatPorts = (ports) => {
  if (!ports || !Array.isArray(ports)) return '-';
 
  return ports.map(port => {
    const parts = [];
    if (port.name) parts.push(port.name);
    parts.push(`${port.port}${port.targetPort ? ':' + port.targetPort : ''}`);
    if (port.protocol) parts.push(port.protocol);
   
    return parts.join(' / ');
  }).join('\n');
};
</script> 