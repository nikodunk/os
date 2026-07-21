#!/bin/bash

set -e

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# get config
if [ -n "$1" ]; then
  CONFIG_FILE="$1"
else
  CONFIG_FILE="etc/terraform-$(dpkg --print-architecture).conf"
fi
BASE_DIR="$PWD"
source "$BASE_DIR"/"$CONFIG_FILE"

echo -e "


#--------------------------------#
# BUILD & LINT CONTAINER IMAGE    #
#--------------------------------#
"

YYYYMMDD="$(date +%Y%m%d)"
IMAGE_TAG="elementaryos-$VERSION-$CHANNEL-$ARCH.$YYYYMMDD$OUTPUT_SUFFIX"
OUTPUT_DIR="$BASE_DIR/builds/$ARCH"
mkdir -p "$OUTPUT_DIR"

podman build \
  --build-arg CHANNEL="$CHANNEL" \
  --build-arg BASECODENAME="$BASECODENAME" \
  --build-arg VERSION="$VERSION" \
  --build-arg CODENAME="$CODENAME" \
  --build-arg NAME="$NAME" \
  --build-arg ARCH="$ARCH" \
  -t "$IMAGE_TAG" \
  -f Containerfile \
  "$BASE_DIR"

bootc container lint "$IMAGE_TAG"

if [ -n "$REGISTRY" ] && [ -n "$IMAGE_NAME" ]; then
  REMOTE_TAG="${VERSION}-${CHANNEL}-${ARCH}.${YYYYMMDD}${OUTPUT_SUFFIX}"
  REMOTE_IMAGE="${REGISTRY}/${IMAGE_NAME}:${REMOTE_TAG}"

  echo -e "
#--------------------------------------------------------#
# PUSH TO REGISTRY SO EXISTING INSTALLS CAN BOOTC UPDATE #
#--------------------------------------------------------#
"

  podman tag "$IMAGE_TAG" "$REMOTE_IMAGE"
  podman push "$REMOTE_IMAGE"

  if [ "$CHANNEL" = "stable" ]; then
    LATEST_IMAGE="${REGISTRY}/${IMAGE_NAME}:latest"
    podman tag "$IMAGE_TAG" "$LATEST_IMAGE"
    podman push "$LATEST_IMAGE"
  fi

  echo "Pushed: $REMOTE_IMAGE"
fi

echo -e "
#---------------------------------------------#
# GENERATE ISO FROM IMAGE FOR NEW INSTALLS    #
#---------------------------------------------#
"

if [ "$BUILD_ISO" = "true" ]; then
  podman run --rm --privileged \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "$OUTPUT_DIR:/output" \
    ghcr.io/osbuild/image-builder-cli:latest \
    --type "bootc-generic-iso" \
    "$IMAGE_TAG"

  ISO_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.iso" -type f | head -1)
  if [ -n "$ISO_FILE" ]; then
    FNAME="elementaryos-$VERSION-$CHANNEL-$ARCH.$YYYYMMDD$OUTPUT_SUFFIX"
    mv "$ISO_FILE" "$OUTPUT_DIR/${FNAME}.iso"
    cd "$OUTPUT_DIR"
    md5sum "${FNAME}.iso" | tee "${FNAME}.md5.txt"
    sha256sum "${FNAME}.iso" | tee "${FNAME}.sha256.txt"
    cd "$BASE_DIR"
  fi
fi

echo -e "
#------------------------#
# IMAGE BUILT SUCCESSFULLY
#------------------------#
"
echo "Image: $IMAGE_TAG"
