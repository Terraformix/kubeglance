<template>
  <ResourceSection 
    title="Secrets" 
    :count="filteredSecrets.length"
    :isEmpty="filteredSecrets.length === 0"
    @search="onSearch"
  >
    <template #summary>
      <div class="flex items-center justify-between">
        <div class="text-3xl font-bold text-card-foreground">{{ stats.total }}</div>
      </div>
    </template>
    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Type</th>
      <th class="pb-2 font-medium text-card-foreground">Keys</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
      <th class="pb-2 font-medium text-card-foreground">Namespace</th>
    </template>
    
    <template #items>
      <tr v-for="secret in filteredSecrets" :key="secret.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground" :title="secret.name">{{ truncateText(secret.name, 65) }}</td>
        <td class="py-2 text-card-foreground">{{ secret.type }}</td>
        <td class="py-2 text-card-foreground">{{ secret.dataKeys?.length || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ formatAge(secret.creationTimestamp) }}</td>
        <td class="py-2 text-card-foreground">{{ secret.namespace }}</td>
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
  secrets: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredSecrets = computed(() => {
  if (!searchQuery.value) return props.secrets;
  
  const query = searchQuery.value.toLowerCase();
  return props.secrets.filter(secret => 
    secret.name.toLowerCase().includes(query) ||
    secret.type?.toLowerCase().includes(query)
  );
});

const stats = computed(() => ({
  total: filteredSecrets.value.length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};
</script> 