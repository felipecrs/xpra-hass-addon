#!/bin/bash

set -eu

if [[ -x /config/initialize.sh ]]; then
    if ! /config/initialize.sh; then
        echo "Error: /config/initialize.sh failed." >&2
    fi
fi

exec bash
