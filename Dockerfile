FROM alpine:latest

# Read the release version from the build args
ARG RELEASE_TAG
ARG DOWNLOAD_URL
ARG DOWNLOAD_HASH
ARG BUILD_DATE

LABEL build="JusteReseau - Version: ${RELEASE_TAG}"
LABEL org.opencontainers.image.description="This is a docker image for Sonarr, that work with Kubernetes security baselines."
LABEL org.opencontainers.image.licenses="WTFPL"
LABEL org.opencontainers.image.source="https://github.com/justereseau/Sonarr"
LABEL maintainer="JusteSonic"

# Do the package update and install
RUN apk update && apk upgrade \
  && apk add --no-cache mono --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  && cert-sync /etc/ssl/certs/ca-certificates.crt \
  && rm -rf /var/cache/apk/*

RUN wget -O /tmp/binary.tar.gz ${DOWNLOAD_URL} \
  && echo "${DOWNLOAD_HASH}  /tmp/binary.tar.gz" | sha256sum -c - \
  && tar -xvzf /tmp/binary.tar.gz -C /opt \
  && rm -rf /tmp/*

# Ensure the Servarr user and group exists and set the permissions
RUN adduser -D -u 1000 -h /config servarr \
  && mkdir -p /config \
  && chown -R servarr:servarr /config \
  && chown -R servarr:servarr /opt/Sonarr

# Set the user
USER servarr

# Expose the port
EXPOSE 8989

# Set the command
CMD ["mono", "--debug", "/opt/Sonarr/Sonarr.exe", "-nobrowser", "-data=/config"]
