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

# Copy source code - copy entire src directory to ensure everything is included
# First, list what's in the build context to debug
COPY . .

# Ensure public directory exists (Vite may need it even if empty, but it's optional)
RUN mkdir -p ./public || true

# Debug: Check what files were actually copied
RUN set -x && \
    echo "=== Checking src directory ===" && \
    ls -la src/ && \
    echo "=== Checking src/lib directory ===" && \
    (ls -la src/lib/ 2>&1 || echo "src/lib NOT FOUND") && \
    echo "=== Listing all TypeScript files ===" && \
    find src -type f \( -name "*.ts" -o -name "*.tsx" \) 2>&1 | head -30

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

