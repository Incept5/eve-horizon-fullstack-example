# Eve Horizon Fullstack Example - API Dockerfile
# Multi-stage build for production optimization

# =============================================================================
# Stage 1: Base
# =============================================================================
FROM node:22-slim AS base

WORKDIR /app
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@latest --activate

# =============================================================================
# Stage 2: Dependencies
# =============================================================================
FROM base AS deps

COPY package.json ./
RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install

# =============================================================================
# Stage 3: Build
# =============================================================================
FROM deps AS build

COPY tsconfig.json ./
COPY src ./src
RUN pnpm build

# =============================================================================
# Stage 4: Production
# =============================================================================
FROM node:22-slim AS production

WORKDIR /app

# OCI image labels — links this package to the source repo in GHCR
LABEL org.opencontainers.image.source="https://github.com/OWNER/REPO"
LABEL org.opencontainers.image.description="API service"

# Create non-root user for security
RUN groupadd --gid 1000 node || true \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node || true

# Copy production artifacts
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./

# Security: run as non-root
USER node

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node -e "fetch('http://localhost:3000/health').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["node", "dist/main.js"]
