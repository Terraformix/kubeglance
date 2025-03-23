<template>
  <ResourceSection 
    title="ConfigMaps" 
    :count="filteredConfigMaps.length"
    :isEmpty="filteredConfigMaps.length === 0"
    @search="onSearch"
  >
    <template #summary>
        
      <div class="flex items-center justify-between">
        <div class="text-3xl font-bold text-card-foreground">{{ stats.total }}</div>
      </div>
    </template>
    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Data</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
      <th class="pb-2 font-medium text-card-foreground">Namespace</th>
    </template>
    
    <template #items>
      <tr v-for="configMap in filteredConfigMaps" :key="configMap.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground" :title="configMap.name">{{ truncateText(configMap.name, 65) }}</td>
        <td class="py-2 text-card-foreground">{{ configMap.dataKeys?.length || 0 }} keys</td>
        <td class="py-2 text-card-foreground">{{ formatAge(configMap.creationTimestamp) }}</td>
        <td class="py-2 text-card-foreground">{{ configMap.namespace }}</td>
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
  configMaps: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredConfigMaps = computed(() => {
  if (!searchQuery.value) return props.configMaps;
  
  const query = searchQuery.value.toLowerCase();
  return props.configMaps.filter(configMap => 
    configMap.name.toLowerCase().includes(query)
  );
});

const stats = computed(() => ({
  total: filteredConfigMaps.value.length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};
</script> 