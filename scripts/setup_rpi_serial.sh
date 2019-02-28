#!/bin/bash
ENABLE_UART="enable_uart=1"
DTOVERLAY="dtoverlay=pi3-miniuart-bt" 
CONFIG_PATH="/boot/config.txt"
CMDLINE_PATH="/boot/cmdline.txt"
CONFIG_BACKUP_PATH="/tmp/backup_config.txt"
CMDLINE_BACKUP_PATH="/tmp/backup_cmdline.txt"
BT_SERIAL_REV=( 900092 900093 9000c1 a02082 a22082 a32082 a020d3 )
IS_BT_SERIAL_REV=0

## Chech if root. Pointless to run without
if [ ! "$(id -u)" -eq 0 ]
then
	echo "You need to be root to run this script kiddo! Come back when you have the right credentials."
	exit
fi

## Configuring UART
echo "Backing up $CONFIG_PATH"
cp $CONFIG_PATH $CONFIG_BACKUP_PATH
echo "Backing up $CMDLINE_PATH"
cp $CMDLINE_PATH $CMDLINE_BACKUP_PATH

echo "Enabling UART"
if grep -Fxq $ENABLE_UART $CONFIG_PATH
then
	echo "UART already set to enabled in $CONFIG_PATH, moving on."
else
	echo $ENABLE_UART >> $CONFIG_PATH
fi

LC_ALL=C perl -alne 'my @filtered ; foreach $token (@F) { push @filtered,$token if not $token =~ /^console=serial/ } ; print "@filtered"' $CMDLINE_BACKUP_PATH > $CMDLINE_PATH

## Detecting revision
echo "Detecting the revision of your Raspberry Pi"
REVISION="$(cat /proc/cpuinfo | grep Revision)"
for var in "${BT_SERIAL_REV[@]}"
do
	if echo "$REVISION" | grep -q "${var}"; then
		echo "Raspberry Pi 3 / Zero detected";
		IS_BT_SERIAL_REV=1
	fi
done

## Disabling serial port console service
echo "Disabling serial port console service"
if IS_BT_SERIAL==0; then
	systemctl stop serial-getty@ttyAMA0.service
	systemctl disable serial-getty@ttyAMA0.service
else
	systemctl stop serial-getty@ttyS0.service
	systemctl disable serial-getty@ttyS0.service
fi

## Disable hardware bluetooth/serial if RPI 3/W
if IS_BT_SERIAL==0; then
	echo "Switching bluetooth coms from hardware to software serial"
	if grep -Fxq $DTOVERLAY $CONFIG_PATH
	then
        	echo "dtoverlay already set to pi3-miniuart-bt, moving on"
	else
        	echo $DTOVERLAY >> $CONFIG_PATH
	fi
fi

## Cleaning up
echo "Deleting temporary files"
rm $CONFIG_BACKUP_PATH
rm $CMDLINE_BACKUP_PATH
echo "Setup done, a reboot is necessary for the changes to take effect."

