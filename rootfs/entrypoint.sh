#!/bin/bash

set -eu

if [[ $# -eq 0 ]]; then
    set -- xpra seamless "${DISPLAY}" --daemon=no --bind-tcp=0.0.0.0:8080 --mdns=no --webcam=no --printing=no --systemd-run=no
fi

if [[ -e /dev/dri/card0 ]]; then
    video_group_id=$(stat -c "%g" /dev/dri/card0)
    if [[ "$(getent group video | cut -d: -f3)" != "${video_group_id}" ]]; then
        groupmod -g "${video_group_id}" video
    fi
    unset video_group_id
fi

export USER="${NON_ROOT_USER}"
export HOME="${NON_ROOT_HOME}"

# If mounted, ownership and permissions may not be correct
chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${HOME}"
chmod 750 "${HOME}"

# https://github.com/Xpra-org/xpra/issues/4383#issuecomment-2408586278
export XDG_RUNTIME_DIR="/run/user/${NON_ROOT_USER_ID}"
mkdir -p "${XDG_RUNTIME_DIR}"
chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# https://github.com/Xpra-org/xpra/issues/4648
mkdir -p "${HOME}/.xpra"
chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${HOME}/.xpra"
chmod 700 "${HOME}/.xpra"

exec s6-setuidgid "${NON_ROOT_USER}" "${@}"
