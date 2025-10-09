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
  echo https://github.com/Prowlarr/Prowlarr/releases/download/v$VERSION/Prowlarr.master.$VERSION.linux-musl-core-x64.tar.gz > /tmp/download_url \
  ;; \
  aarch64) \
  echo https://github.com/Prowlarr/Prowlarr/releases/download/v$VERSION/Prowlarr.master.$VERSION.linux-musl-core-arm64.tar.gz > /tmp/download_url \
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
  rm -rf /build/Prowlarr.Update

FROM alpine:latest

LABEL org.opencontainers.image.description="This is a docker image for Prowlarr, that work with Kubernetes security baselines."
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

# Download the custom definitions from Jackett
RUN mkdir -p /config/Definitions/Custom && \
  wget -O /config/Definitions/Custom/yggtorrent.yml https://raw.githubusercontent.com/Jackett/Jackett/master/src/Jackett.Common/Definitions/yggtorrent.yml && \
  wget -O /config/Definitions/Custom/yggcookie.yml https://raw.githubusercontent.com/Jackett/Jackett/master/src/Jackett.Common/Definitions/yggcookie.yml && \
  chown -R servarr:servarr /config/Definitions

# Set the user
USER servarr

# Expose the port
EXPOSE 8989

# Set the command
CMD ["/app/Prowlarr", "-nobrowser", "-data=/config"]
