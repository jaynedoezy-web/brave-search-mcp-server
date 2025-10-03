# -------------------------
# Builder stage
# -------------------------
FROM node:22-alpine AS builder

# Install any system deps needed for build
RUN apk add --no-cache openssl

WORKDIR /app

# Copy manifests first for cache efficiency
COPY ./package.json ./package-lock.json ./

# Install ALL dependencies (including dev)
RUN npm ci --ignore-scripts

# Copy source and config
COPY ./src ./src
COPY ./tsconfig.json ./tsconfig.json

# Build TypeScript into dist/
RUN npm run build


# -------------------------
# Release (fast build) stage
# -------------------------
FROM node:22-alpine AS release

# Install runtime system deps if needed
RUN apk add --no-cache openssl

WORKDIR /app

# Copy built app and production dependencies directly from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json

# Drop root for safety
USER node

# Railway usually injects $PORT; expose for clarity
EXPOSE 8080

CMD ["node", "dist/index.js"]
