import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  define: {
    global: {},
  },
  server: {
    proxy: {
      // Proxy /api requests to the backend server in development
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      },
    },
    watch: {
      usePolling: true
    }
  },
});
