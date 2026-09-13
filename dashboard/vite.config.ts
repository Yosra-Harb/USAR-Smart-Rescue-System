import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// During local development the browser talks only to Vite on localhost:5173.
// Vite forwards /api requests to FastAPI on 127.0.0.1:8000.
// This keeps the browser on a single origin and avoids local CORS/browser
// loopback edge cases while preserving the same FastAPI API contract.
export default defineConfig({
  plugins: [react()],
  server: {
    host: "127.0.0.1",
    port: 5173,
    proxy: {
      "/api": {
        target: "http://127.0.0.1:8000",
        changeOrigin: true,
      },
    },
  },
});
