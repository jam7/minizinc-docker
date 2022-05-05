#!/bin/bash -eu

CMD="/usr/local/bin/minizinc"
INIT="--init"
TTY=""

case $# in
0) ;;
*) case .$1 in
   .*sh|.*bash) CMD="$1"; shift; INIT=""; TTY="-ti";;
   esac
   ;;
esac

case "$CMD" in
/bin/sh) ;; # Run /bin/sh as an administrator
*) ENVS+=("-e" MINIZINC_UID="$( id -u )")
   ENVS+=("-e" MINIZINC_GID="$( id -g )")
   ENVS+=("-e" MINIZINC_USER="$( id -un )")
   ENVS+=("-e" MINIZINC_GROUP="$( id -gn )")
   ;;
esac

exec docker run $TTY $INIT --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/work \
    -v /tmp:/tmp \
    "${ENVS[@]}" \
    jam7/minizinc "$CMD" "$@"
