#!/bin/bash

exec dbus-send --system --dest=org.freedesktop.DBus --type=method_call /org/freedesktop/DBus org.freedesktop.DBus.ListNames &>/dev/null
