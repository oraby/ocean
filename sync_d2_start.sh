#!/bin/sh
LATEST_SYNC_SCRIPT="sync_d2_execute.sh"
set -xe
curl https://raw.githubusercontent.com/sociomantic-tsunami/ocean-d2/cli_sync/${LATEST_SYNC_SCRIPT} > ${LATEST_SYNC_SCRIPT}
chmod +x ${LATEST_SYNC_SCRIPT}
./${LATEST_SYNC_SCRIPT}
