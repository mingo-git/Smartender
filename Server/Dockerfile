# =============================================================================
# Smartender Backend V2 - Multi-Stage Docker Build
# WebSocket-enabled Real-time Backend - Port 17051
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
    tzdata

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

# Build the application with optimization
RUN go build \
    -ldflags="-w -s -X main.version=2.0-websocket -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -a -installsuffix cgo \
    -o smartender-backend \
    main.go

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

# Start command
CMD ["/app/smartender-backend"]

# =============================================================================
# Build Arguments (for CI/CD)
# =============================================================================
ARG BUILD_VERSION="2.0-websocket"
ARG BUILD_DATE
ARG VCS_REF

# Labels for container management
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$BUILD_VERSION \
      org.label-schema.schema-version="1.0" \
      smartender.port=17051 \
      smartender.websocket="enabled" \
      smartender.upgrade="from-v1"