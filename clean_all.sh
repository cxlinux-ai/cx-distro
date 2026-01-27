#!/bin/bash

#==========================
# Set up the environment
#==========================
set -e                  # exit on error
set -o pipefail         # exit on pipeline error
set -u                  # treat unset variable as error
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

function clean_all() {
    # This clean function will clean up everything built
    echo "Cleaning up..."
    sudo umount ./src/new_building_os/sys || sudo umount -lf ./src/new_building_os/sys || true
    sudo umount ./src/new_building_os/proc || sudo umount -lf ./src/new_building_os/proc || true
    sudo umount ./src/new_building_os/dev || sudo umount -lf ./src/new_building_os/dev || true
    sudo umount ./src/new_building_os/run || sudo umount -lf ./src/new_building_os/run || true
    sudo rm -rf ./src/new_building_os || true
    sudo rm -rf ./src/image || true
    sudo rm -rf ./src/dist || true
}

# =============   main  ================
cd $SCRIPT_DIR

clean_all
