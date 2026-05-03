# ── Stage 1: Builder ──────────────────────────────────────────
FROM node:18-alpine AS builder

# Set working directory inside the container
WORKDIR /app

# Copy package files first (separate layer = better cache)
COPY package*.json ./

# Install ALL dependencies including devDependencies (we need typescript to compile)
RUN npm ci

# Copy the rest of the source code
COPY . .

# Compile TypeScript to JavaScript
# Since there's no build script we call tsc directly
RUN npx tsc

# ── Stage 2: Runner ───────────────────────────────────────────
FROM node:18-alpine AS runner

WORKDIR /app

# Create a non-root group and user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies (no typescript, no jest, no ts-jest)
RUN npm ci --only=production

# Copy the compiled JavaScript from the builder stage
COPY --from=builder /app/dist ./dist

# Switch to non-root user
USER appuser

# Tell Docker this container listens on port 3000
EXPOSE 3000

# Start the app
CMD ["node", "dist/index.js"]