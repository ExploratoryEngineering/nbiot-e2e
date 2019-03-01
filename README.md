# End to end testing for Telenor NB-IoT

These tools enable automatic firmware updates on devices that periodically send NB-IoT data messages to a server that sends an alert whenever it detects dropped or duplicate messages.

## Preparing an end device

### What you'll need
* [Install and configure the aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* Raspberry PI 3 B+
* Raspberry PI power supply
* microSD card for the Raspberry PI
* If attaching an Arduino UNO to the pi
    * Arduino UNO
    * USB A to USB B cable (for the UNO)
    * EE-NBIOT-01 board
    * Adapter board with voltage divider (100Ω and 220Ω resistor) for TX ([schematic](https://docs.nbiot.engineering/tutorials/arduino-basic.html))


### Install steps

1. Download latest [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-11-15/2018-11-13-raspbian-stretch-lite.zip) and burn to the microSD card using [Etcher](https://www.balena.io/etcher/)
1. Mount the SD card and create an empty file called _ssh_ to enable SSH access
1. If the pi __has__ to use WiFi (Ethernet preferred), add a file named wpa_supplicant.conf in the root of the SD card:

    Update the file with _SSID_ and _password_ and remove the _network_ definition that won't be used

            ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
            update_config=1
            country=no
            
            network={
                ssid="no_password_SSID"
                key_mgmt=NONE
            }
            
            network={
                ssid="password_protected_SSID"
                psk="password"
            }

1. Connect the Raspberry PI using Ethernet and power up

1. ssh pi@raspberrypi.local (password is raspberry)

1. `cd _nbiot-e2e_/scripts`

1. Run the setup script and follow instructions (takes ~20 minutes)
    
        ./run_setup_rpi.sh
    
The pi should now be up and running the end to end test.

## Remote access to the pi

The pi's are connected to AWS Systems Manager, so we can use Systems Manager to remotely execute scripts on a pi.

### Run single command on a nbiot-e2e pi

1. `cd scripts/remote`
1. List the managed instances: `aws ssm describe-instance-information`
1. Copy the instance ID of the pi you want to connect to
1. `INSTANCE_ID=_managed instance id_ ./exec.sh "echo This command will run on the pi, wait for execution to finish and output the response"`

### Run single command on all the nbiot-e2e pis'

`exec-all.sh` executes the arguments on all the nbiot-e2e pis' and send the
responses to the SSM-RunCommand-Output log stream in Cloud Watch. It then
checks the Cloud Watch logs every second and prints the output.

1. `cd scripts/remote`
1. `./exec-all.sh command`
1. Wait for responses. Press <kbd>CTRL</kbd> + <kbd>C</kbd> to exit.


### SSH into the pi

1. If it's the first time, you need to get the pi's public ssh key and add it to the e2e server:

        `INSTANCE_ID=_managed instance id_ ./getsshpubkey.sh`

    Copy the value and add it to the end of `.ssh/authorized_keys` on the e2e server

1. ssh to the e2e server
1. ssh to the pi from the e2e server:

        ssh -o StrictHostKeyChecking=no -p 2222 e2e@localhost
