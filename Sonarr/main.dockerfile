FROM alpine:latest AS builder

# Set the working directory
WORKDIR /build

# Get the config file
COPY appconfig.yaml /conf.yml

# Get the download URL and download the binary
RUN apk add --no-cache yq && \
  export VERSION=$(yq e '.version' /conf.yml | sed 's/v//g') && \
  case $(uname -m) in \
  x86_64) \
  echo https://github.com/Sonarr/Sonarr/releases/download/v$VERSION/Sonarr.main.$VERSION.linux-musl-x64.tar.gz > /tmp/download_url \
  ;; \
  aarch64) \
  echo https://github.com/Sonarr/Sonarr/releases/download/v$VERSION/Sonarr.main.$VERSION.linux-musl-arm64.tar.gz > /tmp/download_url \
  ;; \
  *) \
  echo "Unsupported architecture : $(uname -m)" \
  exit 1 \
  ;; \
  esac

# Download and extract the binary
RUN echo "Download URL: $(cat /tmp/download_url)" && \
  wget -O /tmp/binary.tar.gz $(cat /tmp/download_url) && \
  tar -xvzf /tmp/binary.tar.gz -C /build --strip-components=1 && \
  rm -rf /build/Sonarr.Update

FROM alpine:latest

LABEL org.opencontainers.image.description="This is a docker image for Sonarr, that work with Kubernetes security baselines."
LABEL org.opencontainers.image.licenses="WTFPL"
LABEL org.opencontainers.image.source="https://github.com/justereseau/Servarr"
LABEL maintainer="JusteSonic"

COPY --from=builder /build /app

# Install runtime dependencies
RUN apk add --no-cache libintl sqlite-libs icu-libs && rm -rf /var/cache/apk/*

# Ensure the Servarr user and group exists and set the permissions
RUN adduser -D -u 1000 -h /config servarr \
  && mkdir -p /config \
  && chown -R servarr:servarr /config \
  && chown -R servarr:servarr /app

COPY --chown=0:1000 --chmod=755 ./scripts /scripts

# Set the user
USER servarr

# Expose the port
EXPOSE 8989

# Set the command
CMD ["/app/Sonarr", "-nobrowser", "-data=/config"]
