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
	sudo cp ~/Arduino/nbiot-e2e/arduino-service/arduino.service /etc/systemd/system/
    sudo systemctl daemon-reload | ts
    sudo systemctl restart arduino | ts
fi

# restart nbiot-service
echo restart nbiot service | ts
sudo cp ~/Arduino/nbiot-e2e/nbiot-service/nbiot.service /etc/systemd/system/
sudo systemctl daemon-reload | ts
sudo systemctl restart nbiot | ts
) &>> ~/log/nbiot-e2e.log

