FROM alpine:latest

# Read the release version from the build args
ARG APP_NAME
ARG APP_ORG
ARG RELEASE_TAG
ARG BRANCH_NAME
ARG OS_NAME

# Set the working directory
WORKDIR /build

# Get the download URL
RUN case $(uname -m) in \
  x86_64) \
  echo https://github.com/Ombi-app/Ombi/releases/download/v${RELEASE_TAG}/linux-x64.tar.gz > /tmp/download_url \
  ;; \
  aarch64) \
  echo https://github.com/Ombi-app/Ombi/releases/download/v${RELEASE_TAG}/linux-arm64.tar.gz > /tmp/download_url \
  ;; \
  *) \
  echo "Unsupported architecture > $(uname -m)" \
  exit 1 \
  ;; \
  esac

# Download and extract the binary
RUN wget -O /tmp/binary.tar.gz `cat /tmp/download_url` && \
  tar -xvzf /tmp/binary.tar.gz -C /build --strip-components=1
