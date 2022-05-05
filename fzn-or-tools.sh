#!/bin/sh -eu

CMD="/usr/local/bin/fzn-or-tools"
INIT="--init"
TTY=""

exec docker run $TTY $INIT --rm \
    -v "$PWD":/work \
    -v /tmp:/tmp \
    -e FZNORTOOLS_UID="$( id -u )" \
    -e FZNORTOOLS_GID="$( id -g )" \
    -e FZNORTOOLS_USER="$( id -un )" \
    -e FZNORTOOLS_GROUP="$( id -gn )" \
    jam7/fzn-or-tools "$CMD" "$@"
