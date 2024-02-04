FROM alpine:latest as builder

# Read the release version from the build args
ARG RELEASE_TAG
ARG RELEASE_DATA
ARG TOOL_NAME

# Set the working directory
WORKDIR /build

# Install the build dependencies
RUN apk update && apk upgrade && apk add --no-cache jq curl

# Get the download URL
RUN case $(uname -m) in \
  x86_64) \
  echo ${RELEASE_DATA} | jq -c '.assets.x64' > /tmp/release_data.json \
  ;; \
  aarch64) \
  echo ${RELEASE_DATA} | jq -c '.assets.arm64' > /tmp/release_data.json \
  ;; \
  *) \
  echo "Unsupported architecture > $(uname -m)" \
  exit 1 \
  ;; \
  esac

# Download and extract the binary
RUN wget -O /tmp/binary.tar.gz $(cat /tmp/release_data.json | jq -r '.url') && \
  echo "$(cat /tmp/release_data.json | jq -r .hash ) /tmp/binary.tar.gz" | sha256sum -c - && \
  tar -xvzf /tmp/binary.tar.gz -C /build --strip-components=1 && \
  rm -rf /build/Sonarr.Update

# Write a launch script
RUN echo "#!/bin/sh" > /build/launch.sh && \
  echo "/bin/${TOOL_NAME} -nobrowser -data=/config" >> /build/launch.sh && \
  chmod +x /build/launch.sh

FROM alpine:latest

LABEL build="JusteReseau - Version: ${RELEASE_TAG}"
LABEL org.opencontainers.image.description="This is a docker image for ${TOOL_NAME}, that work with Kubernetes security baselines."
LABEL org.opencontainers.image.licenses="WTFPL"
LABEL org.opencontainers.image.source="https://github.com/justereseau/Servarr"
LABEL maintainer="JusteSonic"

COPY --from=builder /build /bin

# Install runtime dependencies
RUN apk add --no-cache libintl sqlite-libs icu-libs && rm -rf /var/cache/apk/*

# Ensure the Servarr user and group exists and set the permissions
RUN adduser -D -u 1000 -h /config servarr \
  && mkdir -p /config \
  && chown -R servarr:servarr /config \
  && chown -R servarr:servarr /bin

# Set the user
USER servarr

# Expose the port
EXPOSE 8989

# Set the command
CMD ["/bin/launch.sh"]
