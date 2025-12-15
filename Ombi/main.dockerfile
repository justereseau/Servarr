FROM alpine:3.22 AS builder

# Set the working directory
WORKDIR /build

# Get the config file
COPY appconfig.yaml /conf.yml

# Get the download URL and download the binary
RUN apk add --no-cache yq && \
  export VERSION=$(yq e '.version' /conf.yml | sed 's/v//g') && \
  case $(uname -m) in \
  x86_64) \
  echo https://github.com/Ombi-app/Ombi/releases/download/v$VERSION/linux-x64.tar.gz > /tmp/download_url \
  ;; \
  aarch64) \
  echo https://github.com/Ombi-app/Ombi/releases/download/v$VERSION/linux-arm64.tar.gz > /tmp/download_url \
  ;; \
  *) \
  echo "Unsupported architecture : $(uname -m)" \
  exit 1 \
  ;; \
  esac

# Download and extract the binary
RUN echo "Download URL: $(cat /tmp/download_url)" && \
  wget -O /tmp/binary.tar.gz $(cat /tmp/download_url) && \
  tar -xvzf /tmp/binary.tar.gz -C /build --strip-components=1

FROM ubuntu:24.04

LABEL org.opencontainers.image.description="This is a docker image for Ombi, that work with Kubernetes security baselines."
LABEL org.opencontainers.image.licenses="WTFPL"
LABEL org.opencontainers.image.source="https://github.com/justereseau/Servarr"
LABEL maintainer="JusteSonic"

COPY --from=builder /build /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y libicu74 && rm -rf /var/cache/apt/*

# Ensure the Servarr user and group exists and set the permissions
RUN echo 'servarr:x:1000:1000:servarr:/home/servarr:/bin/sh' >> /etc/passwd \
  && echo 'servarr:x:1000:' >> /etc/group \
  && mkdir -p /config && chown -R servarr:servarr /config \
  && chown -R servarr:servarr /app \
  && chmod +x /app/Ombi

# Set the user
USER servarr

# Expose the port
EXPOSE 3579

WORKDIR /app

# Set the command
CMD ["/app/Ombi", "--storage=/config", "--host=http://*:3579"]
