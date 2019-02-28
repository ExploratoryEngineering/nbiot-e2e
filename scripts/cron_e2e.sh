#!/bin/bash
set -euf -o pipefail
(
~/Arduino/nbiot-e2e/scripts/check_for_updates.sh ~/Arduino/nbiot-e2e | ts

# install new patches
~/Arduino/nbiot-e2e/scripts/patches/install_all.sh

if [ -e ~/.arduino-config.json ]; then
    # build and restart arduino-service
    cd ~/Arduino/nbiot-e2e/arduino-service
    /usr/local/go/bin/go build | ts
    git checkout -- ../go.sum # discard local modifications to go.sum
    echo restart arduino service | ts
    sudo systemctl stop arduino | ts
    sudo systemctl start arduino | ts
else
    # build and restart raspberrypi-service
    cd ~/Arduino/nbiot-e2e/raspberrypi-service
    /usr/local/go/bin/go build | ts
    git checkout -- ../go.sum # discard local modifications to go.sum
    echo restart raspberrypi service | ts
    sudo systemctl stop raspberrypi | ts
    sudo systemctl start raspberrypi | ts
fi
) &>> ~/log/nbiot-e2e.log
