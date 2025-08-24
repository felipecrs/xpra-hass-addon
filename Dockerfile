ARG DEBIAN_CODENAME="trixie"


FROM alpine:3 AS init-as-root-build

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN apk add build-base --no-cache
RUN apk add shc --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

RUN --mount=type=bind,source=shc/init_as_root.sh,target=/init_as_root.sh \
    CFLAGS="-static" shc -S -r -f /init_as_root.sh -o /init-as-root; \
    chown root:root /init-as-root; \
    chmod 4755 /init-as-root


FROM debian:${DEBIAN_CODENAME}

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV TZ="UTC"
ENV LC_ALL="C.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

# Install basic requirements
ARG DEBIAN_FRONTEND="noninteractive"
RUN apt-get update; \
    apt-get install --no-install-recommends -y \
        curl wget ca-certificates gpg tar xz-utils whiptail locales tzdata; \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" | tee /etc/timezone; \
    dpkg-reconfigure -f noninteractive tzdata; \
    echo -e "${LANG} UTF-8" | tee /etc/locale.gen; \
    locale-gen; \
    rm -rf /var/lib/apt/lists/*

# Install xpra
ARG DEBIAN_CODENAME
RUN wget -q -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc; \
    wget -q -O "/etc/apt/sources.list.d/xpra.sources" "https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/${DEBIAN_CODENAME}/xpra-beta.sources"; \
    apt-get update; \
    # there's too many important recommends, it is easier to opt-out rather than opt-in
    apt-get install --install-recommends -y \
        # avoid xpra-client-gtk3 by avoiding xpra meta package
        xpra-server xpra-audio-server xpra-x11 xpra-codecs-extras \
        # avoid unnecessary recommends
        gstreamer1.0-pipewire- python3-cups- python3-paramiko- python3-dnspython- python3-zeroconf- cups-*- xterm-; \
    apt-get install --no-install-recommends -y \
        # xpra-client is needed for the health check
        # Xdummy is better than xvfb
        # gnome-menus is because of https://github.com/Xpra-org/xpra/issues/4644
        # xdg-utils because it is cool
        # terminator to provide some terminal emulator
        # x11-utils for tools like xmessage
        xpra-client xserver-xorg-video-dummy gnome-menus fluxbox xdg-utils terminator nano x11-utils; \
    mkdir -p /run/dbus; \
    rm -rf /var/lib/apt/lists/*

ARG S6_OVERLAY_VERSION="3.2.1.0"
RUN wget -q -O- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        | tar -C / -Jxpf -; \
    wget -q -O- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-$(uname -m).tar.xz" \
        | tar -C / -Jxpf -

# Fails the container if any service fails to start
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"
# Waits for all services to start before running CMD
ENV S6_CMD_WAIT_FOR_SERVICES="1"
# Honors the timeout-up for each service
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0"
# Honors container's environment variables on CMD
ENV S6_KEEP_ENV="1"

ENV NON_ROOT_USER="xpra-addon"
ENV NON_ROOT_USER_ID="1000"
ENV NON_ROOT_HOME="/home/${NON_ROOT_USER}"
RUN groupadd -g "${NON_ROOT_USER_ID}" "${NON_ROOT_USER}"; \
    useradd -l -d "${NON_ROOT_HOME}" -u "${NON_ROOT_USER_ID}" -g "${NON_ROOT_USER_ID}" -m "${NON_ROOT_USER}" -s /bin/bash -p ""; \
    usermod -aG xpra,audio,pulse,video "${NON_ROOT_USER}"; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        sudo; \
    rm -rf /var/lib/apt/lists/*; \
    echo "${NON_ROOT_USER} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${NON_ROOT_USER}"; \
    sudo -u "${NON_ROOT_USER}" true

# https://github.com/Xpra-org/xpra/issues/4383#issuecomment-2408586278
ENV XDG_RUNTIME_DIR="/run/user/${NON_ROOT_USER_ID}"
RUN mkdir -p "${XDG_RUNTIME_DIR}"; \
    chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${XDG_RUNTIME_DIR}"; \
    chmod 700 "${XDG_RUNTIME_DIR}"

COPY ./rootfs /
COPY --from=init-as-root-build /init-as-root /init-as-root

USER ${NON_ROOT_USER}

ENV USER="${NON_ROOT_USER}"
ENV HOME="${NON_ROOT_HOME}"

ENV DISPLAY=":10"

WORKDIR "${NON_ROOT_HOME}"

EXPOSE 8080

ENTRYPOINT ["/init-as-root"]
CMD []

HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=15s --start-interval=5s \
  CMD xpra connect-test tcp://127.0.0.1:8080 || exit 1
