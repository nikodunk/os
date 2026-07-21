FROM ghcr.io/jmarrero/ubuntu-bootc:latest

ARG CHANNEL=daily
ARG BASECODENAME=resolute
ARG VERSION=9.0
ARG CODENAME=tanit
ARG NAME="elementary OS"
ARG ARCH=amd64

LABEL org.opencontainers.image.title="${NAME}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="elementary OS bootc image" \
      org.opencontainers.image.base.name="ghcr.io/jmarrero/ubuntu-bootc:latest" \
      os.channel="${CHANNEL}" \
      os.codename="${CODENAME}"

COPY etc/config/archives/elementary.key /etc/apt/trusted.gpg.d/elementary.gpg
COPY etc/config/archives/patches.key /etc/apt/trusted.gpg.d/patches.gpg
COPY etc/config/archives/patches.pref /etc/apt/preferences.d/os-patches.pref

RUN echo "Types: deb" > /etc/apt/sources.list.d/elementary.sources \
    && echo "URIs: https://ppa.launchpadcontent.net/elementary-os/${CHANNEL}/ubuntu" >> /etc/apt/sources.list.d/elementary.sources \
    && echo "Suites: ${BASECODENAME}" >> /etc/apt/sources.list.d/elementary.sources \
    && echo "Components: main" >> /etc/apt/sources.list.d/elementary.sources \
    && echo "Signed-By: /etc/apt/trusted.gpg.d/elementary.gpg" >> /etc/apt/sources.list.d/elementary.sources \
    && echo "Types: deb" > /etc/apt/sources.list.d/os-patches.sources \
    && echo "URIs: https://ppa.launchpadcontent.net/elementary-os/os-patches/ubuntu" >> /etc/apt/sources.list.d/os-patches.sources \
    && echo "Suites: ${BASECODENAME}" >> /etc/apt/sources.list.d/os-patches.sources \
    && echo "Components: main" >> /etc/apt/sources.list.d/os-patches.sources \
    && echo "Signed-By: /etc/apt/trusted.gpg.d/patches.gpg" >> /etc/apt/sources.list.d/os-patches.sources

RUN apt-get update \
    && apt-get install -y elementary-desktop elementary-minimal elementary-standard \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/lib/systemd/system/apparmor.service.d \
    && printf '[Unit]\nConditionPathExists=\n' > /usr/lib/systemd/system/apparmor.service.d/99_enable_in_live_mode.conf

RUN bootc container lint
