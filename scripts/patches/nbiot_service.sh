#!/bin/bash

dir=`dirname "$0"`
test_file="${dir}/nbiot_service.installed"

if [ -e "$test_file" ]; then
	exit 0
fi

echo "enabling nbiot service"

sudo "${dir}/setup_rpi_serial.sh"

sudo tee -a /var/awslogs/etc/awslogs.conf <<EOL
[/home/e2e/log/nbiot-service.log]
datetime_format = %b %d %H:%M:%S
file = /home/e2e/log/nbiot-service.log
initial_position = start_of_file
log_group_name = /home/e2e/log/nbiot-service.log
buffer_duration = 5000
log_stream_name = {hostname}
EOL

echo "install the nbiot-service as a systemd service"
sudo cp ~/Arduino/nbiot-e2e/nbiot-service/nbiot.service /etc/systemd/system/

echo "enable nbiot service"
sudo systemctl enable nbiot.service

touch "$test_file"

echo "nbiot service installed.  Rebooting"
sudo reboot
