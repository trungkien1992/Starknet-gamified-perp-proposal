# syntax=docker/dockerfile:1

# --- Builder stage ---
FROM rust:1.82-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    build-essential \
    g++ \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install nightly toolchain for edition2024 support
RUN rustup install nightly && rustup default nightly

WORKDIR /app
COPY services/core-service/ .
COPY proto/ /app/proto/
COPY scripts/migrations/ ./scripts/migrations/
RUN cargo build --release

# --- Runtime stage ---
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install --allow-unauthenticated -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    ca-certificates \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Add a new sources.list file for the US Debian mirror
RUN echo 'deb http://ftp.us.debian.org/debian bookworm main\ndeb http://ftp.us.debian.org/debian bookworm-updates main\ndeb http://security.debian.org/debian-security bookworm-security main' > /etc/apt/sources.list.d/mirror.list

WORKDIR /app

# Copy the compiled binary
COPY --from=builder /app/target/release/core-service /usr/local/bin/core-service

# Copy source code and Cargo files for testing
COPY --from=builder /app/src ./src
COPY --from=builder /app/Cargo.toml ./Cargo.toml
COPY --from=builder /app/Cargo.lock ./Cargo.lock
COPY --from=builder /app/build.rs ./build.rs
COPY --from=builder /app/proto ./proto

# Install Rust nightly and Cargo for testing
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install --allow-unauthenticated -y \
    curl \
    build-essential \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && rustup install nightly && rustup default nightly \
    && rm -rf /var/lib/apt/lists/*

# Set PATH to include cargo
ENV PATH="/root/.cargo/bin:${PATH}"

# Default command runs the service
CMD ["core-service"]
