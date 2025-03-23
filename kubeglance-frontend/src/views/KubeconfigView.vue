<template>
  <div class="space-y-6 bg">
    <div class="flex flex-col space-y-4">
      <h1 class="text-2xl font-bold tracking-tight text-card-foreground">Cluster Configuration</h1>
      
      <!-- Kubeconfig Upload Card -->
      <div class="bg-card rounded-lg shadow-md border border-border overflow-hidden">
        <div class="p-6">
          <h2 class="font-semibold mb-4 text-card-foreground">Upload Kubeconfig</h2>
          
          <!-- Drag and Drop Zone -->
          <div
            class="border-2 border-dashed border-border rounded-lg p-8 text-center hover:border-primary/50 transition-colors"
            :class="{ 'border-primary': isDragging }"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @drop.prevent="handleFileDrop"
          >
            <div class="space-y-4">
              <div class="flex justify-center">
                <DocumentPlusIcon class="size-10 text-primary"/>
              </div>
              
              <!-- Upload Instructions -->
              <div class="text-card-foreground">
                <p class="text-lg font-medium">Drop your kubeconfig file here</p>
                <p class="text-sm text-muted-foreground mt-1">or click to select file</p>
              </div>
              
              <!-- File Input (hidden) -->
              <input
                type="file"
                ref="fileInput"
                class="hidden"
                @change="handleFileSelect"
              />
              
              <!-- Browse Button -->
              <button
                @click="$refs.fileInput.click()"
                class="inline-flex items-center px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-colors"
              >
                Browse Files
              </button>
            </div>
          </div>
          
          <!-- Selected File Info -->
          <div v-if="selectedFile" class="mt-4 p-4 bg-card-muted rounded-md">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <DocumentTextIcon class="size-6 text-primary"/>
                <div>
                  <p class="font-medium text-card-foreground">{{ selectedFile.name }}</p>
                  <p class="text-sm text-muted-foreground">{{ formatFileSize(selectedFile.size) }}</p>
                </div>
              </div>
              
              <!-- Remove File Button -->
              <button
                @click="clearSelectedFile"
                class="text-muted-foreground hover:text-card-foreground"
              >
                <XMarkIcon class="size-6"/>
              </button>
            </div>
          </div>
          
          <!-- Upload Button -->
          <div class="mt-6 flex justify-end">
            <button
              @click="uploadFile"
              :disabled="!selectedFile || isUploading || isValidating"
              class="inline-flex items-center space-x-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg 
                v-if="isUploading || isValidating"
                class="animate-spin w-5 h-5"
                fill="none" 
                stroke="currentColor" 
                viewBox="0 0 24 24" 
                xmlns="http://www.w3.org/2000/svg"
              >
                <path 
                  stroke-linecap="round" 
                  stroke-linejoin="round" 
                  stroke-width="2" 
                  d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                ></path>
              </svg>
              <span>{{ 
                isValidating ? 'Validating...' : 
                isUploading ? 'Uploading...' : 
                'Upload Kubeconfig' 
              }}</span>
            </button>
          </div>
        </div>
      </div>
      
      <!-- Status Messages -->
      <div v-if="statusMessage" class="mt-4">
        <div 
          class="p-4 rounded-md"
          :class="{
            'bg-success/20 text-success': statusMessage.type === 'success',
            'bg-warning/20 text-warning': statusMessage.type === 'error'
          }"
        >
          <p class="text-sm font-medium">{{ statusMessage.text }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import apiService from '../services/apiService.js';
import { DocumentPlusIcon, DocumentTextIcon, XMarkIcon } from '@heroicons/vue/24/outline';
import jsYaml from 'js-yaml';

const router = useRouter();
const fileInput = ref(null);
const selectedFile = ref(null);
const isDragging = ref(false);
const isUploading = ref(false);
const isValidating = ref(false);
const statusMessage = ref(null);

// Handle file selection
const handleFileSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    validateAndSetFile(file);
  }
};

// Handle file drop
const handleFileDrop = (event) => {
  isDragging.value = false;
  const file = event.dataTransfer.files[0];
  if (file) {
    validateAndSetFile(file);
  }
};

// Validate kubeconfig content
const isValidKubeconfig = async (file) => {
  try {
    isValidating.value = true;
    
    // Read file content
    const fileContent = await readFileContent(file);
    let config;
    
    // Try parsing as YAML first (most common for kubeconfig)
    try {
      config = jsYaml.load(fileContent);
    } catch (yamlError) {
      // If YAML parsing fails, try JSON
      try {
        config = JSON.parse(fileContent);
      } catch (jsonError) {
        return {
          isValid: false,
          message: 'The file is not a valid kubeconfig. Unable to parse as YAML or JSON.'
        };
      }
    }
    
    // Check for essential kubeconfig properties
    if (!config) {
      return { isValid: false, message: 'Empty configuration file.' };
    }
    
    // Check for required sections in kubeconfig
    const requiredSections = ['apiVersion', 'clusters', 'contexts', 'current-context', 'kind', 'users'];
    const missingSections = requiredSections.filter(section => !config[section]);
    
    if (missingSections.length > 0) {
      return {
        isValid: false,
        message: `Not a valid kubeconfig: Missing required sections: ${missingSections.join(', ')}`
      };
    }
    
    // Check if 'kind' field is 'Config'
    if (config.kind !== 'Config') {
      return {
        isValid: false,
        message: `Not a valid kubeconfig: 'kind' should be 'Config', found '${config.kind}'`
      };
    }
    
    // Check if clusters, contexts, and users are non-empty arrays
    if (!Array.isArray(config.clusters) || config.clusters.length === 0) {
      return {
        isValid: false,
        message: 'Not a valid kubeconfig: No clusters defined'
      };
    }
    
    if (!Array.isArray(config.contexts) || config.contexts.length === 0) {
      return {
        isValid: false,
        message: 'Not a valid kubeconfig: No contexts defined'
      };
    }
    
    if (!Array.isArray(config.users) || config.users.length === 0) {
      return {
        isValid: false,
        message: 'Not a valid kubeconfig: No users defined'
      };
    }
    
    // Check if current-context references a valid context
    const contextNames = config.contexts.map(ctx => ctx.name);
    if (!contextNames.includes(config['current-context'])) {
      return {
        isValid: false,
        message: `Not a valid kubeconfig: current-context '${config['current-context']}' not found in defined contexts`
      };
    }
    
    return { isValid: true };
  } catch (error) {
    console.error('Validation error:', error);
    return {
      isValid: false,
      message: `Failed to validate file: ${error.message}`
    };
  } finally {
    isValidating.value = false;
  }
};

// Read file content as text
const readFileContent = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (event) => resolve(event.target.result);
    reader.onerror = (error) => reject(error);
    reader.readAsText(file);
  });
};

// Validate and set the selected file
const validateAndSetFile = async (file) => {
  // Validate content directly without checking extension
  const validation = await isValidKubeconfig(file);
  
  if (!validation.isValid) {
    statusMessage.value = {
      type: 'error',
      text: validation.message
    };
    return;
  }
  
  // File is valid
  selectedFile.value = file;
  statusMessage.value = {
    type: 'success',
    text: 'Valid kubeconfig file detected!'
  };
};

// Clear selected file
const clearSelectedFile = () => {
  selectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = '';
  }
  statusMessage.value = null;
};

// Format file size
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

// Upload the file
const uploadFile = async () => {
  if (!selectedFile.value) return;
  
  isUploading.value = true;
  statusMessage.value = null;
  
  try {
    await apiService.uploadKubeconfig(selectedFile.value);
    
    statusMessage.value = {
      type: 'success',
      text: 'Kubeconfig uploaded successfully!'
    };
    
    // Redirect to dashboard after successful upload
    setTimeout(() => {
      router.push('/');
    }, 1500);
    
  } catch (error) {
    statusMessage.value = {
      type: 'error',
      text: error.message || 'Failed to upload kubeconfig file'
    };
  } finally {
    isUploading.value = false;
  }
};
</script>