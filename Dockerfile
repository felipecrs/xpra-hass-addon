ARG DEBIAN_CODENAME="trixie"
FROM debian:${DEBIAN_CODENAME}

ENV LC_ALL="C.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US.UTF-8"

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update; \
    apt-get install --no-install-recommends -y \
        curl wget ca-certificates gpg tar xz-utils locales; \
    locale-gen; \
    rm -rf /var/lib/apt/lists/*

# TODO: use --no-install-recommends to reduce image size. WIP packages list:
#   xpra xpra-x11 xpra-html5 adduser xdg-user-dirs xdg-utils python3-xdg gnome-backgrounds
ARG DEBIAN_CODENAME
RUN wget -q -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc; \
    wget -q -O "/etc/apt/sources.list.d/xpra.sources" "https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/${DEBIAN_CODENAME}/xpra.sources"; \
    apt-get update; \
    apt-get install --install-recommends -y \
        xpra xterm-; \
    mkdir -p /run/dbus; \
    apt-get install --no-install-recommends -y \
        gnome-menus terminator; \
    rm -rf /var/lib/apt/lists/*

ARG WINE_VERSION="10.13"
ARG WINE_BRANCH="staging"
ARG WINETRICKS_VERSION="73b92d2f3c117cd21d96e2fc807e041e7a89fec3"
ARG DOCKER_WINE_VERSION="6284e6ab06aef285263d1f77a5b1554afb1e83d9"
RUN dpkg --add-architecture i386; \
    mkdir -p /etc/apt/keyrings; \
    wget -q -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -; \
    wget -q -O "/etc/apt/sources.list.d/winehq.sources" "https://dl.winehq.org/wine-builds/debian/dists/${DEBIAN_CODENAME}/winehq-${DEBIAN_CODENAME}.sources"; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        "winehq-${WINE_BRANCH}=${WINE_VERSION}~*" zenity cabextract; \
    rm -rf /var/lib/apt/lists/*; \
    wget -q -O /usr/bin/winetricks "https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks"; \
    chmod +x /usr/bin/winetricks; \
    wget -q -O- "https://raw.githubusercontent.com/scottyhardy/docker-wine/${DOCKER_WINE_VERSION}/download_gecko_and_mono.sh" \
        | bash -s -- "${WINE_VERSION}"

ARG S6_OVERLAY_VERSION="3.2.1.0"
RUN wget -q -O- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
        | tar -C / -Jxpf -; \
    wget -q -O- "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-$(uname -m).tar.xz" \
        | tar -C / -Jxpf -

# Fails the container if any service fails to start
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2"
# Waits for all services to start before running CMD
ENV S6_CMD_WAIT_FOR_SERVICES="1"
# Honors container's environment variables on CMD
ENV S6_KEEP_ENV="1"

ENV NON_ROOT_USER="xpra-addon"
ENV NON_ROOT_USER_ID="1000"
ENV NON_ROOT_HOME="/home/${NON_ROOT_USER}"
RUN groupadd -g "${NON_ROOT_USER_ID}" "${NON_ROOT_USER}"; \
    useradd -l -d "${NON_ROOT_HOME}" -u "${NON_ROOT_USER_ID}" -g "${NON_ROOT_USER_ID}" -m "${NON_ROOT_USER}" -s /bin/bash -p ""; \
    usermod -aG xpra,audio,video "${NON_ROOT_USER}"; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        sudo; \
    rm -rf /var/lib/apt/lists/*; \
    echo "${NON_ROOT_USER} ALL=(ALL) NOPASSWD:ALL" | tee "/etc/sudoers.d/${NON_ROOT_USER}"; \
    sudo -u "${NON_ROOT_USER}" true

ENV WINEPREFIX="${NON_ROOT_HOME}/wine-prefix"
ENV WINEARCH="win32"
ENV DISPLAY=":0"

# https://github.com/Xpra-org/xpra/issues/4383#issuecomment-2408586278
ENV XPRA_PRIVATE_PULSEAUDIO=0

COPY ./rootfs /

EXPOSE 8080

ENTRYPOINT ["/init", "/entrypoint.sh"]
CMD []
