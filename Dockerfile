ARG S6_OVERLAY_VERSION="3.1.0.0"
ARG S6_OVERLAY_RELEASE="https://github.com/just-containers/s6-overlay/releases/download/"
ARG S6_OVERLAY_PAK_EXT=".tar.xz"
ARG ALPINE_VERSION="3.19.1"


FROM scratch AS s6-base-downloader
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT
ADD "${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch${S6_OVERLAY_PAK_EXT}" /s6overlay-base.tar.xz


FROM --platform=${TARGETPLATFORM} alpine:$ALPINE_VERSION AS s6-bin-downloader
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT
ARG S6_OVERLAY_RELEASE_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}${S6_OVERLAY_PAK_EXT}"
ARG S6_OVERLAY_HASH_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}${S6_OVERLAY_PAK_EXT}.sha256"

RUN set -eux \
    && apk add --no-cache wget \
    && wget -O /s6overlay-bin.tar.xz "$(echo ${S6_OVERLAY_RELEASE_URL} | sed 's/linux\///g' | sed 's/amd64/x86_64/g' | sed 's/arm64/aarch64/g' | sed 's/arm\/v7/armhf/g')"


FROM --platform=${TARGETPLATFORM} alpine:$ALPINE_VERSION AS s6-sha256-sums-downloader
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT
ARG S6_OVERLAY_BASE_HASH_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch${S6_OVERLAY_PAK_EXT}.sha256"
ARG S6_OVERLAY_BIN_HASH_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}${S6_OVERLAY_PAK_EXT}.sha256"

RUN set -eux \
    && apk add --no-cache wget \
    && wget -O /s6overlay-base.tar.xz.sha256 "${S6_OVERLAY_BASE_HASH_URL}" \
    && wget -O /s6overlay-bin.tar.xz.sha256 "$(echo "${S6_OVERLAY_BIN_HASH_URL}" | sed 's/linux\///g' | sed 's/amd64/x86_64/g' | sed 's/arm64/aarch64/g' | sed 's/arm\/v7/armhf/g')" \
    && echo "$(cat /s6overlay-base.tar.xz.sha256 | cut -d' ' -f1)  /s6overlay-base.tar.xz" > /SHA256SUMS \
    && echo "$(cat /s6overlay-bin.tar.xz.sha256 | cut -d' ' -f1)  /s6overlay-bin.tar.xz" >> /SHA256SUMS \
    && rm /s6overlay-base.tar.xz.sha256 \
    && rm /s6overlay-bin.tar.xz.sha256


FROM alpine:$ALPINE_VERSION AS rootfs-builder

COPY --from=s6-sha256-sums-downloader ["/SHA256SUMS", "/"]
COPY --from=s6-base-downloader ["/s6overlay-base.tar.xz", "/s6overlay-base.tar.xz"]
COPY --from=s6-bin-downloader  ["/s6overlay-bin.tar.xz", "/s6overlay-bin.tar.xz"]

WORKDIR "/rootfs-build/"

RUN set -eux \
    && sha256sum -c /SHA256SUMS \
    && apk add --no-cache tar xz \
    && tar -Jxpf /s6overlay-base.tar.xz -C /rootfs-build \
    && tar -Jxpf /s6overlay-bin.tar.xz -C /rootfs-build


FROM scratch AS s6-rootfs

COPY --from=rootfs-builder ["/rootfs-build/", "/"]