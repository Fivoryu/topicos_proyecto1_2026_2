import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    // Dev proxy: same-origin requests so the browser sends SameSite=Lax
    // cookies to the API (cross-origin fetch drops them). In production the
    // API is served behind the same origin by the deployment reverse proxy.
    proxy: {
      "/api": "http://127.0.0.1:8000",
    },
  },
});
