FROM alpine:latest AS builder

# Read the release version from the build args
ARG RELEASE_TAG
ARG PRODUCT_NAME
ARG BRANCH_NAME
ARG OS_NAME

# Set the working directory
WORKDIR /build

# Get the download URL
RUN case $(uname -m) in \
  x86_64) \
  echo https://github.com/${PRODUCT_NAME}/${PRODUCT_NAME}/releases/download/v${RELEASE_TAG}/${PRODUCT_NAME}.${BRANCH_NAME}.${RELEASE_TAG}.${OS_NAME}-x64.tar.gz > /tmp/download_url \
  ;; \
  aarch64) \
  echo https://github.com/${PRODUCT_NAME}/${PRODUCT_NAME}/releases/download/v${RELEASE_TAG}/${PRODUCT_NAME}.${BRANCH_NAME}.${RELEASE_TAG}.${OS_NAME}-arm64.tar.gz > /tmp/download_url \
  ;; \
  *) \
  echo "Unsupported architecture > $(uname -m)" \
  exit 1 \
  ;; \
  esac

# Download and extract the binary
RUN wget -O /tmp/binary.tar.gz $(cat /tmp/download_url) && \
  tar -xvzf /tmp/binary.tar.gz -C /build --strip-components=1 && \
  rm -rf /build/${PRODUCT_NAME}.Update

# Write a launch script
RUN echo "#!/bin/sh" > /build/launch.sh && \
  echo "/bin/${PRODUCT_NAME} -nobrowser -data=/config" >> /build/launch.sh && \
  chmod +x /build/launch.sh

FROM alpine:latest

LABEL build="JusteReseau - Version: ${RELEASE_TAG}"
LABEL org.opencontainers.image.description="This is a docker image for ${PRODUCT_NAME}, that work with Kubernetes security baselines."
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
