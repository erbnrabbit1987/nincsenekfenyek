# Frontend Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with retry logic and cache cleaning
# Clean npm cache and retry on network errors
RUN npm cache clean --force && \
    npm install --legacy-peer-deps --fetch-retries=5 --fetch-retry-mintimeout=20000 || \
    (sleep 10 && npm cache clean --force && npm install --legacy-peer-deps --fetch-retries=5 --fetch-retry-mintimeout=20000)

# Copy source code
COPY . .

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

