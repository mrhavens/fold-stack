FROM debian:bullseye

RUN apt-get update && apt-get install -y curl git unzip && \
    curl -LO https://github.com/radicle-dev/radicle-cli/releases/download/v0.5.0/radicle-cli_0.5.0_amd64.deb && \
    apt install -y ./radicle-cli_0.5.0_amd64.deb && \
    rm radicle-cli_0.5.0_amd64.deb

# Optional: verify it's installed
RUN rad --version

# Replace this:
# ENTRYPOINT ["rad"]

# With this: (keeps container alive)
CMD ["tail", "-f", "/dev/null"]
