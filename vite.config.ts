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
      build: {
        rollupOptions: {
          output: {
            // Grundbausteine in eigene Pakete. Sie aendern sich selten; nach
            // einem Update laedt der Browser nur den App-Code neu, React,
            // Supabase und Framer Motion bleiben im Zwischenspeicher.
            // Nur was ohnehin beim Start gebraucht wird -- jspdf, Diagramme
            // und Karten bleiben nachgeladen.
            manualChunks(id) {
              if (!id.includes('node_modules')) return;
              if (/node_modules\/(react|react-dom|scheduler|react-router|react-router-dom|@remix-run)\//.test(id)) return 'react';
              if (id.includes('node_modules/@supabase/') || id.includes('node_modules/iceberg-js/')) return 'supabase';
              if (/node_modules\/(framer-motion|motion-dom|motion-utils)\//.test(id)) return 'motion';
            },
          },
        },
      },
      resolve: {
        alias: {
          '@': path.resolve(__dirname, '.'),
        }
      }
    };
});
