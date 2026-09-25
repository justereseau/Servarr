FROM ubuntu:24.04 AS builder

ARG TARGETARCH

# Set the working directory
WORKDIR /build

# Get the config file
COPY appconfig.yaml /conf.yml

# Download the package and extract it without running its maintainer scripts
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
  VERSION=$(sed -n 's/^version: *v\{0,1\}//p' /conf.yml) && \
  case "$TARGETARCH" in \
  amd64|arm64) ;; \
  *) echo "Unsupported architecture : $TARGETARCH" && exit 1 ;; \
  esac && \
  URL="https://downloads.plex.tv/plex-media-server-new/$VERSION/debian/plexmediaserver_${VERSION}_${TARGETARCH}.deb" && \
  echo "Download URL: $URL" && \
  curl -fL -o /tmp/plex.deb "$URL" && \
  dpkg-deb -x /tmp/plex.deb /build

FROM ubuntu:24.04

LABEL org.opencontainers.image.description="This is a docker image for Plex Media Server, that work with Kubernetes security baselines."
LABEL org.opencontainers.image.licenses="WTFPL"
LABEL org.opencontainers.image.source="https://github.com/justereseau/Servarr"
LABEL maintainer="JusteSonic"

ENV LANG="C.UTF-8" \
  LC_ALL="C.UTF-8" \
  HOME="/config" \
  PLEX_MEDIA_SERVER_HOME="/usr/lib/plexmediaserver" \
  PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR="/config/Library/Application Support" \
  PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="6" \
  PLEX_MEDIA_SERVER_INFO_VENDOR="Docker" \
  PLEX_MEDIA_SERVER_INFO_DEVICE="Docker Container"

# Install runtime dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates tzdata tini xmlstarlet && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/usr/lib/plexmediaserver /usr/lib/plexmediaserver

# Ensure the Plex user and group exists and set the permissions
RUN userdel -r ubuntu \
  && useradd -u 1000 -U -d /config -s /bin/false plex \
  && mkdir -p /config /transcode \
  && chown plex:plex /config /transcode

COPY --chown=0:1000 --chmod=755 ./scripts /scripts

# Set the user
USER plex

# Expose the port
EXPOSE 32400

# Set the command
ENTRYPOINT ["/usr/bin/tini", "--", "/scripts/entrypoint.sh"]
