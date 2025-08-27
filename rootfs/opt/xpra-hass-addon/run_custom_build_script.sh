#!/bin/bash

set -ex

if [[ -x /opt/xpra-hass-addon/custom-build/run.sh ]]; then
    cd /tmp
    exec /command/s6-setuidgid "${NON_ROOT_USER}" /opt/xpra-hass-addon/custom-build/run.sh
fi
