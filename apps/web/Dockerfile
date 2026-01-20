# Eve Horizon Fullstack Example - Web Dockerfile
# Multi-stage build: Node for build, nginx for serving

# =============================================================================
# Stage 1: Build
# =============================================================================
FROM node:22-slim AS build

WORKDIR /app
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package.json ./
RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src
RUN pnpm build

# =============================================================================
# Stage 2: Production (nginx)
# =============================================================================
FROM nginx:alpine AS production

# Copy built assets from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Custom nginx config for SPA routing
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /health { \
        return 200 "ok"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
