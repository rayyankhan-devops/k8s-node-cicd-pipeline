FROM node:22-alpine AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev --ignore-scripts && \
    mkdir -p node_modules && \
    npm cache clean --force

FROM alpine:3.21 AS runner

LABEL org.opencontainers.image.title="k8s-cicd-app" \
      org.opencontainers.image.description="Ultra-lightweight cloud-native Node.js microservice" \
      org.opencontainers.image.version="1.0.0"

RUN apk add --no-cache nodejs icu-data-en && \
    addgroup -g 1001 -S node && \
    adduser -u 1001 -S node -G node && \
    rm -rf /usr/share/man /usr/share/doc /var/cache/apk/* /tmp/*

WORKDIR /app

# Set production environment variables
ENV NODE_ENV=production \
    PORT=6767

# Copy dependencies and application code with non-root ownership
COPY --chown=node:node --from=dependencies /app/node_modules ./node_modules
COPY --chown=node:node package*.json ./
COPY --chown=node:node index.js ./

# Run as unprivileged user for security compliance (K8s PSA restricted)
USER node

# Document the exposed port
EXPOSE 6767

# Self-contained healthcheck using native Node.js (no curl/wget required)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('node:http').get('http://localhost:' + (process.env.PORT || 6767) + '/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

# Exec form ensures Node receives OS signals directly (SIGTERM/SIGINT) for graceful shutdown
CMD ["node", "index.js"]
