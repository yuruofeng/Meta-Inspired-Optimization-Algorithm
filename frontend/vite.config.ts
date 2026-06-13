import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
      '/ws': {
        target: 'ws://localhost:8000',
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    // 仅在开发环境启用 sourcemap
    sourcemap: mode === 'development',
    rollupOptions: {
      output: {
        // 代码分割配置
        manualChunks: {
          // React 相关
          'vendor-react': ['react', 'react-dom'],
          // Ant Design 相关
          'vendor-antd': ['antd', '@ant-design/icons'],
          // Zustand 状态管理
          'vendor-zustand': ['zustand'],
        },
      },
    },
  },
}));
