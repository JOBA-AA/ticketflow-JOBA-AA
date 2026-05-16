# ── Stage 1: Builder ──────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY node_modules ./node_modules

COPY . .

ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build

# ── Stage 2: Runner ───────────────────────────────────────────
FROM node:18-alpine AS runner

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/next.config.js ./next.config.js

USER appuser

EXPOSE 3000

CMD ["node_modules/.bin/next", "start"]