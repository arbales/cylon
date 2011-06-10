#!/bin/sh
# poor man's reloader.
# re-starts evilbot when he dies of an error.

until /usr/bin/env coffee cylon.coffee; do
    echo "Cylon crashed with exit code $?. respawning.." >&2
    sleep 1
done
