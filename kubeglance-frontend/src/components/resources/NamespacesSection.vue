<template>
  <ResourceSection 
    title="Namespaces" 
    :count="filteredNamespaces.length"
    :isEmpty="filteredNamespaces.length === 0"
    @search="onSearch"
  >
    <template #summary>
      <div class="flex items-center justify-between">
        <div class="text-3xl font-bold text-card-foreground">{{ stats.active }} / {{ stats.total }}</div>
      </div>
    </template>
    
    <template #headers>
      <th class="pb-2 font-medium text-card-foreground">Name</th>
      <th class="pb-2 font-medium text-card-foreground">Status</th>
      <th class="pb-2 font-medium text-card-foreground">Pods</th>
      <th class="pb-2 font-medium text-card-foreground">Age</th>
    </template>
    
    <template #items>
      <tr v-for="namespace in filteredNamespaces" :key="namespace.name" class="hover:bg-card-hover transition-colors">
        <td class="py-2 text-card-foreground">{{ namespace.name }}</td>
        <td class="py-2">
          <span class="bg-success/20 text-success px-2 py-0.5 rounded-full text-xs font-medium">
            {{ namespace.status || 'Active' }}
          </span>
        </td>
        <td class="py-2 text-card-foreground">{{ namespace.totalPods || 0 }}</td>
        <td class="py-2 text-card-foreground">{{ formatAge(namespace.creationTimestamp) }}</td>
      </tr>
    </template>
  </ResourceSection>
</template>

<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import ResourceSection from '../ResourceSection.vue';
import { formatAge } from '../../helper/formatters';

const props = defineProps({
  namespaces: {
    type: Array,
    required: true
  }
});

const searchQuery = ref('');

const filteredNamespaces = computed(() => {
  if (!searchQuery.value) return props.namespaces;
  
  const query = searchQuery.value.toLowerCase();
  return props.namespaces.filter(namespace => 
    namespace.name.toLowerCase().includes(query) ||
    namespace.status?.toLowerCase().includes(query)
  );
});

const stats = computed(() => ({
  total: filteredNamespaces.value.length,
  active: filteredNamespaces.value.filter(ns => ns.status !== 'Terminating').length
}));

const onSearch = (query) => {
  searchQuery.value = query;
};
</script> 