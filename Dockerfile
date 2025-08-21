ARG DEBIAN_CODENAME="trixie"
FROM debian:${DEBIAN_CODENAME}

ENV HOME="/root"
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

ARG DEBIAN_CODENAME
RUN wget -q -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc; \
    wget -q -O "/etc/apt/sources.list.d/xpra.sources" "https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/${DEBIAN_CODENAME}/xpra.sources"; \
    apt-get update; \
    # --no-install-recommends: xpra xpra-x11 xpra-html5 adduser xdg-user-dirs xdg-utils python3-xdg gnome-backgrounds
    apt-get install --install-recommends -y \
        xpra xterm-; \
    mkdir -p /run/dbus; \
    apt-get install --no-install-recommends -y \
        supervisor gnome-menus terminator; \
    rm -rf /var/lib/apt/lists/*

# RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; \
#     apt-get update; \
#     apt-get install --no-install-recommends -y \
#         ./google-chrome-stable_current_amd64.deb; \
#     rm -f google-chrome-stable_current_amd64.deb; \
#     rm -rf /var/lib/apt/lists/*

# RUN wget -q -O /etc/apt/keyrings/mozilla.asc https://packages.mozilla.org/apt/repo-signing-key.gpg; \
#     echo "deb [signed-by=/etc/apt/keyrings/mozilla.asc] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list/ \
#     apt-get update; \
#     apt-get install --no-install-recommends -y \
#         firefox; \
#     rm -rf /var/lib/apt/lists/*

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

ENV WINEPREFIX="/root/prefix32"
ENV WINEARCH="win32"
ENV DISPLAY=":0"

COPY ./xpra.conf /etc/xpra/xpra.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["supervisord"]

# RUN apt-get update; \
#     apt-get install --no-install-recommends -y \
#         fluxbox; \
#     rm -rf /var/lib/apt/lists/*
