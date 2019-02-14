# End to end testing for Telenor NB-IoT

These tools enable automatic firmware updates on devices that periodically send NB-IoT data messages to a server that sends an alert whenever it detects dropped or duplicate messages.

## Preparing an end device

### What you'll need
* Raspberry PI 3
* Raspberry PI power supply
* microSD card for the Raspberry PI
* Arduino UNO
* USB A to USB B cable (for the UNO)
* EE-NBIOT-01 board
* Either
* Adapter board with voltage divider (100Ω and 220Ω resistor) for TX
    * See schematic here: https://docs.nbiot.engineering/tutorials/arduino-basic.html
* [Install and configure the aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

### Install steps

1. Download latest [Raspbian Stretch Lite](https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-11-15/2018-11-13-raspbian-stretch-lite.zip) and burn to the microSD card using [Etcher](https://www.balena.io/etcher/)
1. Mount the SD card and create an empty file called _ssh_ to enable SSH access
1. If the pi __has__ to use WiFi (Ethernet preferred), add a file named wpa_supplicant.conf in the root of the SD card:

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

1. If the pi will use and Arduino UNO with EE-NBIOT-01, connect it to one of the pi's USB ports
    1. NB! Make sure you use `ENABLE_ARDUINO=1` when running the `setup_rpi.sh` script later.
1. Connect the Raspberry PI using Ethernet and power up
1. You might need to remove raspberrypi.local from ~/.ssh/known_hosts if you've ssh-ed a different pi with the same hostname before
1. ssh pi@raspberrypi.local (password is raspberry)
1. Generate a new AWS SSM activation: `aws ssm create-activation --default-instance-name nbiot-e2e-pi --iam-role nbiot-e2e-pi --registration-limit 1 --region eu-west-1`
1. Generate a new AWS IAM access key: `aws iam create-access-key --user-name nbiot-e2e-pi`
1. Create a [GitHub personal access token](https://github.com/settings/tokens/new) with «repo - Full control of private repositories» checked
    1. This will only be used once, to add the pi's public ssh key as a deploy key to nbiot-e2e on GitHub Enterprise. This gives the pi access to clone and pull updates without using a persons ssh key.
1. cd _nbiot-e2e_/scripts
1. Replace the hostname number with the next unused number and insert keys (takes ~20 minutes)
    
    ssh pi@raspberrypi.local "NEWHOSTNAME=nbiot-e2e-XX \
    SSM_ACT_CODE=_AWS activation code_ \
    SSM_ACT_ID=_AWS activation ID_  \
    AWS_ACCESS_KEY=_AWS access key_ \
    AWS_SECRET_KEY=_AWS secret key_ \
    GHE_TOKEN=_GitHub Enterprise Personal Access token_ \
    ENABLE_ARDUINO=0 \
    bash -s --" < setup_rpi.sh
    
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
    1. `INSTANCE_ID=_managed instance id_ ./getsshpubkey.sh`
    1. Copy the value and add it to the end of `.ssh/authorized_keys` on the e2e server
1. ssh to the e2e server
1. ssh to the pi from the e2e server:
    1. ssh -o StrictHostKeyChecking=no -p 2222 e2e@localhost
