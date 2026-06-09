import path from 'path';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, '.', '');
    return {
      server: {
        port: 3000,
        host: '0.0.0.0',
      },
      plugins: [react()],
      define: {
        'process.env.API_KEY': JSON.stringify(env.GEMINI_API_KEY),
        'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY)
      },
      resolve: {
        alias: {
          '@': path.resolve(__dirname, '.'),
          'firebase/app': path.resolve(__dirname, './services/supabase-bridge.ts'),
          'firebase/firestore': path.resolve(__dirname, './services/supabase-bridge.ts'),
          'firebase/storage': path.resolve(__dirname, './services/supabase-bridge.ts'),
          'firebase/auth': path.resolve(__dirname, './services/supabase-bridge.ts'),
        }
      }
    };
});
