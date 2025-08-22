#!/bin/bash
#
# This script needs to be compiled with shc enabling the suid bit, so even
# though the container starts as a non-root user, it operates as if it was
# ran as root.

set -eu

if [[ -e /dev/dri/card0 ]]; then
    host_video_group_id=$(stat -c "%g" /dev/dri/card0)
    container_video_group_id=$(getent group video | cut -d: -f3)
    if [[ "${container_video_group_id}" != "${host_video_group_id}" ]]; then
        groupmod -g "${host_video_group_id}" video
    fi
    unset host_video_group_id container_video_group_id

    if ! /command/s6-setuidgid "${NON_ROOT_USER}" test -r /dev/dri/card0; then
        echo "Error: unable to fix access to /dev/dri/card0." >&2
        exit 1
    fi
fi

# If mounted, ownership and permissions may not be correct
chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${HOME}"
chmod 750 "${NON_ROOT_HOME}"

# https://github.com/Xpra-org/xpra/issues/4648
mkdir -p "${NON_ROOT_HOME}/.xpra"
chown "${NON_ROOT_USER_ID}:${NON_ROOT_USER_ID}" "${NON_ROOT_HOME}/.xpra"
chmod 700 "${NON_ROOT_HOME}/.xpra"

if [[ $# -eq 0 ]]; then
    set -- xpra seamless "${DISPLAY}" --daemon=no --bind-tcp=0.0.0.0:8080 --mdns=no --webcam=no --printing=no --systemd-run=no --xvfb=Xdummy
fi

exec /init /command/s6-setuidgid "${NON_ROOT_USER}" "$@"
