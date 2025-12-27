# Frontend Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Increase Node.js memory limit and disable npm update checks
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV npm_config_update_notifier=false

# Copy package files
COPY package*.json ./

# Install dependencies with increased memory and retry logic
# Note: Removed npm cache clean --force as it causes segmentation fault in Alpine
RUN npm install --legacy-peer-deps --fetch-retries=5 --fetch-retry-mintimeout=20000 --prefer-offline --no-audit || \
    (sleep 15 && npm install --legacy-peer-deps --fetch-retries=5 --fetch-retry-mintimeout=20000 --prefer-offline --no-audit)

# Copy source code (copy src directory first to ensure it's included)
COPY src ./src
COPY index.html ./
COPY vite.config.ts ./
COPY tsconfig.json ./
COPY tsconfig.node.json ./
COPY tailwind.config.js ./
COPY postcss.config.js ./
# Ensure public directory exists (Vite may need it even if empty, but it's optional)
RUN mkdir -p ./public || true

# Debug: Check if lib/api.ts exists before build
RUN ls -la src/lib/ && cat src/lib/api.ts | head -10

# Build
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

