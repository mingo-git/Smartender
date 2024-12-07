# Stage 1: Build
# Verwende das offizielle Go-Image als Basis
FROM golang:1.21-alpine AS builder

# Install git and other necessary packages for dependencies
RUN apk add --no-cache git

# Set the working directory
WORKDIR /app

# Copy Go modules manifests
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Ensure the binary is built for the correct architecture
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

# Build the application binary
RUN go build -o main .

# Stage 2: Run
FROM alpine:3.18

# Install the Cloud SQL Proxy client and necessary libraries
RUN apk add --no-cache libc6-compat bash

# Copy the compiled binary from the builder stage
COPY --from=builder /app/main /app/main

# Copy .env file if necessary
COPY .env /app/.env

# Set the working directory
WORKDIR /app

# Expose the port on which the service runs
EXPOSE 8080

# Run the binary
CMD ["/app/main"]