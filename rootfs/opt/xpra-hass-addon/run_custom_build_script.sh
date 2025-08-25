#!/bin/bash

set -ex

if [[ -x /opt/xpra-hass-addon/custom-build/run.sh ]]; then
    exec /opt/xpra-hass-addon/custom-build/run.sh
fi
