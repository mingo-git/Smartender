# =============================================================================
# Smartender Backend V2 - WebSocket Upgrade
# Existing Infrastructure (Port 17051)
# =============================================================================

# =============================================================================
# Stage 1: Build
# =============================================================================
FROM golang:1.21-alpine AS builder

# Metadata
LABEL maintainer="Smartender Team"
LABEL version="2.0-websocket-upgrade"
LABEL description="Smartender Backend with WebSocket support - Port 17051"

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    tzdata \
    openssh-client

# Set working directory
WORKDIR /app

# Copy dependency files first (better Docker layer caching)
COPY go.mod go.sum ./

# Download and verify dependencies
RUN go mod download && \
    go mod verify

# Copy source code
COPY . .

# Build configuration
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Build the application with optimization and version info
RUN go build \
    -ldflags="-w -s -X main.version=2.0-websocket -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ) -X main.port=17051" \
    -a -installsuffix cgo \
    -o smartender-backend \
    main.go

# Verify binary
RUN ls -la smartender-backend && \
    ./smartender-backend --version 2>/dev/null || echo "Binary built successfully"

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    bash \
    curl \
    postgresql-client \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S smartender && \
    adduser -u 1001 -S smartender -G smartender

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/smartender-backend /app/smartender-backend

# Make binary executable
RUN chmod +x /app/smartender-backend

# Copy configuration files
COPY --from=builder /app/.env.example /app/.env.example

# Create directories for logs and data
RUN mkdir -p /app/logs /app/data && \
    chown -R smartender:smartender /app

# Switch to non-root user
USER smartender

# Health check for Smartender Backend
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${APP_PORT:-17051}/status || exit 1

# Expose Smartender port
EXPOSE 17051

# Environment variables with Smartender defaults
ENV APP_PORT=17051 \
    GIN_MODE=release \
    TZ=Europe/Berlin \
    LOG_LEVEL=info

# Create startup script for better logging
USER root
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'echo "🚀 Starting Smartender Backend V2 on port ${APP_PORT:-17051}"' >> /app/start.sh && \
    echo 'echo "🐳 Container: $(hostname)"' >> /app/start.sh && \
    echo 'echo "📅 Started at: $(date)"' >> /app/start.sh && \
    echo 'echo "🔧 Environment: ${ENVIROMENT:-dev}"' >> /app/start.sh && \
    echo 'echo "📡 WebSocket endpoint: ws://localhost:${APP_PORT:-17051}/api/ws"' >> /app/start.sh && \
    echo 'echo "🏥 Health check: http://localhost:${APP_PORT:-17051}/status"' >> /app/start.sh && \
    echo 'echo "===========================================" ' >> /app/start.sh && \
    echo 'exec /app/smartender-backend "$@"' >> /app/start.sh && \
    chmod +x /app/start.sh && \
    chown smartender:smartender /app/start.sh

USER smartender

# Start command
CMD ["/app/start.sh"]

# =============================================================================
# Build Arguments (for CI/CD)
# =============================================================================
ARG BUILD_VERSION="2.0-websocket"
ARG BUILD_DATE
ARG VCS_REF
ARG SMARTENDER_PORT="17051"

# Labels for container management
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$BUILD_VERSION \
      org.label-schema.schema-version="1.0" \
      smartender.port=$SMARTENDER_PORT \
      smartender.websocket="enabled" \
      smartender.upgrade="from-v1"