<template>
  <div class="bg-card rounded-lg shadow-md hover:shadow-lg transition-shadow border border-border">

    <div class="p-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-semibold text-card-foreground">{{ title }}</h2>

        <div class="flex items-center space-x-2">
          <button @click="isExpanded = !isExpanded" class="text-muted-foreground hover:text-card-foreground">
            <ChevronUpIcon v-if="isExpanded" class="w-6 h-6"/>
            <ChevronDownIcon  v-else class="w-6 h-6"/>
          </button>
        </div>
      </div>
      
      <!-- Resource Summary -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <slot name="summary"></slot>
      </div>
    </div>
    
    <!-- Expanded Content -->
    <div v-if="isExpanded" class="border-t border-border">
      <div class="p-4 bg-card-muted">
        <div class="space-y-4">
          <!-- Search and Filter -->
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div class="relative flex-1">
              <input
                type="text"
                v-model="searchQuery"
                @input="onSearchInput"
                :placeholder="`Search ${title.toLowerCase()}...`"
                class="w-full pl-10 pr-10 py-2 bg-card border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
              />

              <MagnifyingGlassIcon class="absolute left-3 top-2.5 w-5 h-5 text-muted-foreground"/>

              <button
                v-if="searchQuery"
                @click="clearSearch"
                class="absolute right-3 top-2.5 text-muted-foreground hover:text-card-foreground"
                title="Clear search"
              >
                <XMarkIcon class="size-6"/>
              </button>
            </div>
            <slot name="actions"></slot>
          </div>

          <!-- Resource Table -->
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="text-left border-b border-border">
                  <slot name="headers"></slot>
                </tr>
              </thead>
              <tbody>
                <slot name="items"></slot>
              </tbody>
            </table>
          </div>

          <!-- Empty State -->
          <div v-if="isEmpty" class="text-center py-8 text-muted-foreground">
            <slot name="empty">
              No items found
            </slot>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineProps, defineEmits, watch } from 'vue';
import { ChevronDownIcon, ChevronUpIcon, XMarkIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline';


const props = defineProps({
  title: {
    type: String,
    required: true
  },
  count: {
    type: Number,
    default: 0
  },
  isEmpty: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['search']);
const isExpanded = ref(false);
const searchQuery = ref('');

// Add watch to emit search event whenever searchQuery changes
watch(searchQuery, (newValue) => {
  emit('search', newValue);
});

const onSearchInput = () => {
  emit('search', searchQuery.value);
};

// Add clear search function
const clearSearch = () => {
  searchQuery.value = '';
  emit('search', '');
};
</script> 