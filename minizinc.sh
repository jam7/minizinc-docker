#!/bin/sh -eu

CMD="/usr/local/bin/minizinc"
INIT="--init"
TTY=""

case .$1 in
.*sh|.*bash) CMD=""; INIT=""; TTY="-ti";;
esac

exec docker run $TTY $INIT --rm \
    -v "$PWD":/work \
    -e MINIZINC_UID="$( id -u )" \
    -e MINIZINC_GID="$( id -g )" \
    -e MINIZINC_USER="$( id -un )" \
    -e MINIZINC_GROUP="$( id -gn )" \
    jam7/minizinc "$CMD" "$@"
