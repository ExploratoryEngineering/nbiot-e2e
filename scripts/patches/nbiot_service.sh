#!/bin/bash
source ./once.sh

function nbiot_service() {
	echo "enabling nbiot service"

    dir=`dirname "$0"`
    test_file="${dir}/nbiot_service.installed"

	sudo "${dir}/setup_rpi_serial.sh"

	echo "install the nbiot-service as a systemd service"
	sudo cp ~/Arduino/nbiot-e2e/nbiot-service/nbiot.service /etc/systemd/system/

	echo "enable nbiot service"
	sudo systemctl enable nbiot.service

	# touch the file ourselves because we are rebooting
	touch "$test_file"

	sudo reboot
}

once nbiot_service
