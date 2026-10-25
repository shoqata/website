import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  // Derselbe Alias wie in vite.config.ts.
  //
  // Er fehlte hier, und damit war jedes Modul untestbar, das '@/...'
  // benutzt -- also unter anderem lib/textbaustein.ts und lib/mahnung.ts,
  // zwei Stellen, an denen Briefe an Mitglieder entstehen. Aufgefallen
  // ist es erst, als ein neuer Test den Import nicht aufloesen konnte.
  // Zwei Konfigurationen, die sich widersprechen, sind schlimmer als
  // eine strenge: die Anwendung baut, der Test nicht, und man haelt das
  // fuer einen Fehler im Test.
  resolve: {
    alias: { '@': path.resolve(__dirname, '.') },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    globals: true,
    // Die Unit-Tests liegen unter tests/unit; src/ gibt es in diesem Projekt nicht.
    include: ['tests/unit/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    // Die Datenbanktests starten je ein Postgres im Prozess (PGlite).
    testTimeout: 30000,
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache', 'tests/e2e', 'tests/security'],
  },
});
