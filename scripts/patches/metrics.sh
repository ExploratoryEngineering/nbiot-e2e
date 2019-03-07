#!/bin/bash
source ./once.sh

function metrics() {
    echo "extract metrics from logs"
    
    echo "install mtail"
    go get -u github.com/google/mtail
    cd /home/e2e/go/src/github.com/google/mtail
    git checkout 6558ed8
    mkdir .d
    PREFIX=/home/e2e/go make install

    echo "install mtail as a systemd service"
    sudo cp /home/e2e/Arduino/nbiot-e2e/pi/mtail.service /etc/systemd/system/
    
    sudo systemctl start mtail.service
    sudo systemctl enable mtail.service
}

once metrics
