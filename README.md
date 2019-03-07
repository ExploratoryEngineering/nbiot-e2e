# End to end testing for Telenor NB-IoT

These tools enable automatic firmware updates on devices that periodically send NB-IoT data messages to a server that sends an alert whenever it detects dropped or duplicate messages.

We use Raspberry Pis to run the end 2 end tests from different locations. The plan is that they will send nbiot-packets by connecting an EE-NBIOT-01 directly to the UART on the Raspberry Pi. Some of them might also have an Arduino attached to compile and test that the Arduino library is working.

## Preparing an end device

### What you'll need
* [Install and configure the aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* Raspberry Pi 3 B+
* Raspberry Pi power supply
* microSD card for the Raspberry Pi
* If attaching an Arduino UNO to the Pi
    * Arduino UNO
    * USB A to USB B cable (for the UNO)
    * EE-NBIOT-01 board
    * Adapter board with voltage divider (100Ω and 220Ω resistor) for TX ([schematic](https://docs.nbiot.engineering/tutorials/arduino-basic.html))


### Install steps

1. Download latest [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-11-15/2018-11-13-raspbian-stretch-lite.zip) and burn to the microSD card using [Etcher](https://www.balena.io/etcher/)
1. Mount the SD card and create an empty file called _ssh_ to enable SSH access
1. If the Pi __has__ to use WiFi (Ethernet preferred), add a file named wpa_supplicant.conf in the root of the SD card:

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

1. Connect the Raspberry Pi using Ethernet and power up

1. ssh pi@raspberrypi.local (password is raspberry)

1. `cd _nbiot-e2e_/scripts`

1. Run the setup script and follow instructions (takes ~20 minutes)
    
        ./run_setup_rpi.sh
    
The Pi should now be up and running the end to end test.

## Remote access to the Pi

The Pis are connected to AWS Systems Manager, so we can use Systems Manager to remotely execute scripts on a Pi.

### Run single command on a nbiot-e2e Pi

1. `cd _nbiot-e2e_/scripts/remote`
1. List the managed instances: `aws ssm describe-instance-information`
1. Copy the instance ID of the Pi you want to connect to
1. `./exec.sh nbiot-e2e-01 "echo This command will run on nbiot-e2e-01, wait for execution to finish and output the response"`

### Run single command on all the nbiot-e2e Pis

`exec-all.sh` executes the arguments on all the nbiot-e2e Pis and send the
responses to the SSM-RunCommand-Output log stream in Cloud Watch. It then
checks the Cloud Watch logs every second and prints the output.

1. `cd _nbiot-e2e_/scripts/remote`
1. `./exec-all.sh command`
1. Wait for responses. Press <kbd>CTRL</kbd> + <kbd>C</kbd> to exit.


### SSH into the Pi

1. `cd _nbiot-e2e_/scripts/remote`
1. If it's the first time, you need to get the Pi's public ssh key and add it to the e2e server (replace XX with pi number):

        `./getsshpubkey.sh nbiot-e2e-XX`

    Copy the STDOUT value and add it to the end of `.ssh/authorized_keys` on the e2e server

1. Open the tunnel from the Pi to the e2e server:

        `./open-tunnel.sh nbiot-e2e-XX`

1. ssh ubuntu@e2e.nbiot.engineering
    1. ssh to the Pi from the e2e server:

            ssh -o StrictHostKeyChecking=no -p 2222 e2e@localhost

    1. You should now be logged in as e2e on the pi

1. When you're done. Remember to close the tunnel:

        `./close-tunnel.sh nbiot-e2e-XX`
