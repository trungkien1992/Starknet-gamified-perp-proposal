# Multi-stage build for game-logic-service
FROM rust:1.82-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libzstd-dev \
    g++ \
    protobuf-compiler \
    build-essential \
    cmake \
    libsasl2-dev \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the service source
COPY services/game-logic-service/ .

# Build the service
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libzstd-dev \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built binary
COPY --from=builder /app/target/release/game-logic-service /usr/local/bin/game-logic-service

# Copy source and config for testing
COPY --from=builder /app/src ./src
COPY --from=builder /app/Cargo.toml ./Cargo.toml
COPY --from=builder /app/Cargo.lock ./Cargo.lock

# Create a non-root user
RUN useradd -r -s /bin/false game-logic

# Change ownership of app directory
RUN chown -R game-logic:game-logic /app

# Expose any necessary ports (if needed for health checks)
EXPOSE 8080

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/game-logic-service"] 