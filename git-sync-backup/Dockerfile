# Stage 1: Build stage
FROM alpine:3.19 AS builder

# Install build dependencies
RUN apk add --no-cache     build-base     git     openssh-client     curl     bash

# Install Rclone (statically compiled binary for Alpine)
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip &&     unzip rclone-current-linux-amd64.zip &&     mv rclone-*-linux-amd64/rclone /usr/bin/ &&     rm -rf rclone-*-linux-amd64 rclone-current-linux-amd64.zip

# Stage 2: Runtime stage
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache     git     openssh-client     bash     inotify-tools     ca-certificates

# Copy Rclone from the builder stage
COPY --from=builder /usr/bin/rclone /usr/bin/rclone

# Set up SSH directory and permissions
RUN mkdir -p /root/.ssh &&     chmod 700 /root/.ssh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /repos

# Define volumes for configuration, secrets, and logs
VOLUME /config/git-sync
VOLUME /repos/local
VOLUME /logs

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD []
