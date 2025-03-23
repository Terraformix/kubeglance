<template>
  <div class="bg-card rounded-lg shadow-md border border-border overflow-hidden">
    <div class="p-6">
      <h2 class="font-semibold mb-4 text-card-foreground">
        {{ title }}
      </h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- CPU Usage Card -->
        <div class="bg-card-muted rounded-lg p-4">
          <div class="flex justify-between items-center mb-2">
            <span class="text-sm font-medium text-card-foreground">CPU Usage</span>
            <span 
              :class="[getCPUColorClass, 'text-sm font-medium px-2 py-1 rounded-full border']"
            >
              {{ cpuUsage }}%
            </span>
          </div>

          <div class="mt-2">
            <Line
              :data="cpuChartData"
              :options="chartOptions"
              class="h-[150px]"
            />
          </div>
        </div>

        <!-- Memory Usage Card -->
        <div class="bg-card-muted rounded-lg p-4">
          <div class="flex justify-between items-center mb-2">
            <span class="text-sm font-medium text-card-foreground">Memory Usage</span>
            <span 
              :class="[
                getMemoryColorClass,
                'text-sm font-medium px-2 py-1 rounded-full border'
              ]"
            >
              {{ memoryUsage }}%
            </span>
          </div>

          <div class="mt-2">
            <Line
              :data="memoryChartData"
              :options="chartOptions"
              class="h-[150px]"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { Line } from 'vue-chartjs';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

const props = defineProps({
  title: {
    type: String,
    default: 'Resource Usage'
  }
});

// Sample data generation
const generateSampleData = (min, max, count) => {
  return Array.from({ length: count }, () => 
    Math.floor(Math.random() * (max - min + 1)) + min
  );
};

const timeLabels = Array.from({ length: 20 }, (_, i) => `${i + 1}m ago`).reverse();
const cpuData = ref(generateSampleData(20, 80, 20));
const memoryData = ref(generateSampleData(30, 90, 20));

// Current usage values (latest data point)
const cpuUsage = computed(() => cpuData.value[cpuData.value.length - 1]);
const memoryUsage = computed(() => memoryData.value[memoryData.value.length - 1]);

// Color classes based on usage
const getCPUColorClass = computed(() => {
  if (cpuUsage.value >= 90) return 'bg-destructive text-destructive-foreground';
  if (cpuUsage.value >= 75) return 'bg-warning text-warning-foreground';
  return 'bg-primary text-primary-foreground';
});

const getMemoryColorClass = computed(() => {
  if (memoryUsage.value >= 90) return 'bg-destructive text-destructive-foreground';
  if (memoryUsage.value >= 75) return 'bg-warning text-warning-foreground';
  return 'bg-primary text-primary-foreground';
});

// Chart data
const cpuChartData = computed(() => ({
  labels: timeLabels,
  datasets: [
    {
      label: 'CPU Usage %',
      data: cpuData.value,
      borderColor: cpuUsage.value >= 75 ? 'rgb(234, 179, 8)' : 'rgb(59, 130, 246)',
      backgroundColor: cpuUsage.value >= 75 ? 'rgba(234, 179, 8, 0.5)' : 'rgba(59, 130, 246, 0.5)',
      tension: 0.4,
      fill: true
    }
  ]
}));

const memoryChartData = computed(() => ({
  labels: timeLabels,
  datasets: [
    {
      label: 'Memory Usage %',
      data: memoryData.value,
      borderColor: memoryUsage.value >= 75 ? 'rgb(234, 179, 8)' : 'rgb(59, 130, 246)',
      backgroundColor: memoryUsage.value >= 75 ? 'rgba(234, 179, 8, 0.5)' : 'rgba(59, 130, 246, 0.5)',
      tension: 0.4,
      fill: true
    }
  ]
}));

// Updated Chart options to remove horizontal gridlines
const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false
    },
    tooltip: {
      mode: 'index',
      intersect: false,
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      max: 100,
      ticks: {
        color: 'rgb(156, 163, 175)'
      },
      grid: {
        display: false  // Remove horizontal gridlines
      }
    },
    x: {
      ticks: {
        color: 'rgb(156, 163, 175)',
        maxRotation: 45,
        minRotation: 45
      },
      grid: {
        display: false
      }
    }
  },
  interaction: {
    intersect: false,
    mode: 'index',
  },
  elements: {
    line: {
      borderWidth: 2
    },
    point: {
      radius: 0,
      hoverRadius: 4
    }
  }
};

// Simulate real-time updates
const updateData = () => {
  cpuData.value = [...cpuData.value.slice(1), Math.floor(Math.random() * 60) + 20];
  memoryData.value = [...memoryData.value.slice(1), Math.floor(Math.random() * 60) + 30];
};

onMounted(() => {
  // Update every 5 seconds
  setInterval(updateData, 5000);
});
</script> 