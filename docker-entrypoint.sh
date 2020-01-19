#!/bin/bash
set -e

# Source docker-entrypoint.sh:
# https://github.com/docker-library/postgres/blob/master/9.4/docker-entrypoint.sh
# https://github.com/kovalyshyn/docker-freeswitch/blob/vanilla/docker-entrypoint.sh

if [ "$1" = 'freeswitch' ]; then

    mkdir -p /var/{run,lib}/freeswitch
    chown -R freeswitch:freeswitch /etc/freeswitch
    chown -R freeswitch:freeswitch /var/{run,lib}/freeswitch

    if [ -d /docker-entrypoint.d ]; then
        for f in /docker-entrypoint.d/*.sh; do
            [ -f "$f" ] && . "$f"
        done
    fi

    exec gosu freeswitch /usr/bin/freeswitch -u freeswitch -g freeswitch -nonat -c
fi

exec "$@"
