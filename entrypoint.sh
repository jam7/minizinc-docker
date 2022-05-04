#!/bin/sh -eu

# This is the entrypoint script for the dockerfile. Executed in the
# container at runtime.  Based on dockcross.

if [[ $# == 0 ]]; then
    # Presumably the image has been run directly, so help the user get
    # started by outputting the dockcross script
    cat /minizinc/minizinc.sh
    exit 0
fi

# If we are running docker natively, we want to create a user in the container
# with the same UID and GID as the user on the host machine, so that any files
# created are owned by that user. Without this they are all owned by root.
# The dockcross script sets the MINIZINC_UID and MINIZINC_GID vars.
if [[ -n "$MINIZINC_UID" ]] && [[ -n "$MINIZINC_GID" ]] && [[ -n "$MINIZINC_GROUP" ]]; then

    addgroup -g $MINIZINC_GID $MINIZINC_GROUP
    adduser -g "" -D -G $MINIZINC_GROUP -u $MINIZINC_UID $MINIZINC_USER
    export HOME=/home/${MINIZINC_USER}
    chown -R $MINIZINC_UID:$MINIZINC_GID $HOME

    # Enable passwordless sudo capabilities for the user
    chown root:$MINIZINC_GID $(which su-exec)
    chmod +s $(which su-exec); sync

    # Run the command as the specified user/group.
    exec su-exec $MINIZINC_UID:$MINIZINC_GID "$@"
else
    # Just run the command as root.
    exec "$@"
fi
