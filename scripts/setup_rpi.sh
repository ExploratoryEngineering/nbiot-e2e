#!/bin/bash

set -euf -o pipefail

export NEWHOSTNAME=${NEWHOSTNAME:=nbiot-e2e}
export TIMEZONE=${TIMEZONE:=Europe/Oslo}
export GO_VERSION=${GO_VERSION:=1.11.4.linux-armv6l}
export ENABLE_ARDUINO=${ENABLE_ARDUINO:=0}

export AWS_REGION=${AWS_REGION:=eu-west-1}
: ${SSM_ACT_CODE:?"SSM_ACT_CODE needs to be set to an AWS activation code"}
: ${SSM_ACT_ID:?"SSM_ACT_ID needs to be set to an AWS activation id"}
export SSM_ACT_CODE=$SSM_ACT_CODE
export SSM_ACT_ID=$SSM_ACT_ID

: ${AWS_ACCESS_KEY:?"AWS_ACCESS_KEY needs to be set to an AWS users access key"}
: ${AWS_SECRET_KEY:?"AWS_SECRET_KEY needs to be set to an AWS users secret key"}
export AWS_ACCESS_KEY=${AWS_ACCESS_KEY}
export AWS_SECRET_KEY=${AWS_SECRET_KEY}

: ${GHE_TOKEN:?"GHE_TOKEN needs to be set to a GitHub Enterprise personal access token with full access to private repos"}
export GHE_TOKEN=${GHE_TOKEN}

echo "Setup settings"
echo "New hostname: ${NEWHOSTNAME}"
echo "Timezone: ${TIMEZONE}"
echo "Go version: ${GO_VERSION}"

echo "change hostname"
sudo sed -i -e "s/raspberrypi/${NEWHOSTNAME}/" /etc/hosts /etc/hostname

echo "update mdns with new hostname (to avoid restarting the pi)"
sudo hostnamectl set-hostname "${NEWHOSTNAME}"
sudo systemctl restart avahi-daemon

echo "add new user"
sudo useradd -m -s /bin/bash e2e

echo "give e2e user sudo privileges"
echo "e2e ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

echo "add e2e user to relevant groups"
sudo usermod -aG adm,dialout,users,netdev,gpio,i2c,spi e2e

echo "switch to e2e user preserving exported environment variables"
sudo --preserve-env -u e2e bash
export HOME=/home/e2e

echo "set timezone"
sudo timedatectl set-timezone ${TIMEZONE}

echo "update apt"
sudo apt-get update

echo "upgrade apt packages"
sudo apt-get dist-upgrade -y -f

echo "install dependencies"
sudo apt-get -y install unattended-upgrades apt-listchanges vim git moreutils jq python3 python3-pip

echo "configure unattended-upgrades"
sudo sed -i -e "s/\/\/Unattended-Upgrade::Automatic-Reboot \"false\";/Unattended-Upgrade::Automatic-Reboot \"true\";/" /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i -e "s/\/\/Unattended-Upgrade::Automatic-Reboot-WithUsers/Unattended-Upgrade::Automatic-Reboot-WithUsers/" /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i -e "s/\/\/ Unattended-Upgrade::SyslogEnable \"false\";/Unattended-Upgrade::SyslogEnable \"true\";/" /etc/apt/apt.conf.d/50unattended-upgrades

echo "install aws cli"
echo "export PATH=~/.local/bin:\$PATH" >> ~/.profile
export PATH=/usr/bin:~/.local/bin:$PATH
pip3 install awscli --upgrade --user
aws configure set aws_access_key_id ${AWS_ACCESS_KEY}
aws configure set aws_secret_access_key ${AWS_SECRET_KEY}

echo "generate SSH keys"
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

echo "add .ssh/authorized keys from AWS SSM Parameter Store"
aws ssm get-parameter --name "ee_ssh_keys" --output json --region ${AWS_REGION} | jq -r '.Parameter.Value' > ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys
if [ -s ~/.ssh/authorized_keys ]; then
    echo "fetced authorized_keys from ssm parameter store"
else
    tee ~/.ssh/authorized_keys <<EOL
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+NgvEW4c9Y5JUW9r/a1Mm72/5VDNNT/6jnalGAeE4vrlnaBTDUGPWoCJYUbvXzSjQgfBTKShjYlj9zMYSsbT3oqWHizY+sVKc6J4w9v7E1UQp3ail57UH03DCch6rHBOHeyFdgMmeVbnhhbq5ebhiesXkQnAfe7K2bfV64OW6bij+fDH3R3hv81whUcaABZHBF59SACYzpPvqldFY+wGbK7ixHachw1qlHIfrs98gFZxF3gzRuxmkcT6VsG0qwloqx+sH+6v+A/R8dj/rOs6zJIYGeA1AALzFlKdVKs8fB32D/pnXTyYbSKPWj6p1zG8X21cKqAGLa4AT5HxcudXj ubuntu@ip-172-31-27-15
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiCzumU7DWkdM3DDknICQv/gP0qb/fWTUKzPaE9SN0NcyFPJNT7ucwOAbAkdptka5+Kc+NQG4W4q/s90sIw3Dr/osz1Ie5EBxnBo2BmeF0vBpnZeV8UY8d3VVSygh58DLUznbldOHQrTs7EBtVNZqu6plf4HCJfXqxD2Ntgd+PmD0jAPRrrpdG6APWVZaoIYbW3T3+pP1rjnel5RKG7iNtHcb1/gVAkCNUEtkP85Wu2axElDYbhjk0753IMUenmldNiCgu0M3e0wQ7u3OY/vhYnmcMwkToyUg6esWHHs/UT4GqEUse9gNz/dxdM3LDKeS9ivF2xxoMBd5fjv4vVYuLUJ3em7gUUyikOCtnH508E9EG7yOXr9U/3RhK8ZGPgCXx7+f7yzoVv+RYzBJMvHy+fbJQ5W2dcKUx78E2les/sJLjxrtlO4VfnybgstDIeRKL0gQ9r/nJ69wiuKHNVoZFK/VJcjzrClV/voxxHmS2evTeZnKExGC3G7uEnlIoja8KCDJuE/9M7pzY7g5is/jhkcR4riQ347bPtuSnwY0xOSw8RU02TNz9Ewhp+NMSp+Uxckdvr4Tu8cS/nLYAZXhL1aUNJgKMBJvFPv/e1jsX1pPQlAUzSxkC4uMCzIYUB56bykESRDb9fX23nhfrIBt6J62yZlPDUv4t3pzE5txFnw== gregers@telenordigital.com
EOL
    chmod 600 ~/.ssh/authorized_keys
    echo "error fetching authorized keys"
    exit 1
fi


echo "modify sshd_config to avoid warning and disable login with password"
sudo sed -i -e 's/^AcceptEnv LANG/#AcceptEnv LANG/' /etc/ssh/sshd_config
sudo sed -i -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service ssh restart

echo "setup AWS Systems Manager"
mkdir /tmp/ssm
curl https://s3.eu-west-1.amazonaws.com/amazon-ssm-eu-west-1/latest/debian_arm/amazon-ssm-agent.deb -o /tmp/ssm/amazon-ssm-agent.deb
sudo dpkg -i /tmp/ssm/amazon-ssm-agent.deb
sudo service amazon-ssm-agent stop

echo "setup AWS CloudWatch with systems manager"
sudo tee /etc/amazon/ssm/seelog.xml <<EOL
<!--amazon-ssm-agent uses seelog logging -->
<!--Seelog has github wiki pages, which contain detailed how-tos references: https://github.com/cihub/seelog/wiki -->
<!--Seelog examples can be found here: https://github.com/cihub/seelog-examples -->
<seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500" minlevel="info">
    <exceptions>
        <exception filepattern="test*" minlevel="error"/>
    </exceptions>
    <outputs formatid="fmtinfo">
        <console formatid="fmtinfo"/>
        <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5"/>
        <filter levels="error,critical" formatid="fmterror">
            <rollingfile type="size" filename="/var/log/amazon/ssm/errors.log" maxsize="10000000" maxrolls="5"/>
        </filter>
        <custom name="cloudwatch_receiver" formatid="fmtdebug" data-log-group="nbiot-e2e-pi"/>
    </outputs>
    <formats>
        <format id="fmterror" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
        <format id="fmtdebug" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
        <format id="fmtinfo" format="%Date %Time %LEVEL %Msg%n"/>
    </formats>
</seelog>
EOL

sudo amazon-ssm-agent -register -code "${SSM_ACT_CODE}" -id "${SSM_ACT_ID}" -region "${AWS_REGION}"
sudo sed -i -e "s/on-failure/always/" /lib/systemd/system/amazon-ssm-agent.service
sudo sed -i -e "s/15min/30s/" /lib/systemd/system/amazon-ssm-agent.service
sudo systemctl daemon-reload
sudo service amazon-ssm-agent start

echo "add ssm tags to instance"
INSTANCE_ID=`aws ssm describe-instance-information --region "${AWS_REGION}" | jq -r '.InstanceInformationList[] | select(.ComputerName == "'"${NEWHOSTNAME}"'") | .InstanceId'`
echo "self instance id: ${INSTANCE_ID}"
aws ssm add-tags-to-resource --resource-type ManagedInstance --resource-id="${INSTANCE_ID}" --tags '[{"Key":"Name","Value":"'"${NEWHOSTNAME}"'"},{"Key":"Collection","Value":"nbiot-e2e-pi"}]' --region "${AWS_REGION}"

echo "install go"
wget -qO "/tmp/go${GO_VERSION}.tar.gz" https://dl.google.com/go/go${GO_VERSION}.tar.gz
sudo tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.tar.gz"
mkdir ~/go
echo "export PATH=/usr/local/go/bin:\$HOME/go/bin:\${PATH}" >> ~/.profile
export PATH=/usr/local/go/bin:$HOME/go/bin:${PATH}

echo "set up logrotate"
sudo tee -a /etc/logrotate.conf <<EOL
/home/e2e/log/*.log {
    weekly
    rotate 4
    compress
    minsize 1k
    postrotate
        systemctl restart arduino
    endscript
    missingok
}
EOL

echo "add deployment key for nbiot-e2e"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
curl -sS -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GHE_TOKEN}" --data '{"title":"'"${NEWHOSTNAME}"'","read_only":"true","key":"'"${SSH_KEY}"'"}' https://ghe.telenordigital.com/api/v3/repos/iot/nbiot-e2e/keys

echo "download nbiot e2e project"
mkdir ~/Arduino
cd ~/Arduino/
ssh-keyscan ghe.telenordigital.com >> ~/.ssh/known_hosts
git clone git@ghe.telenordigital.com:iot/nbiot-e2e.git

echo "make log directory"
mkdir ~/log

if [ "$ENABLE_ARDUINO" = "1" ]; then
    echo "enabling arduino service"

    echo "install arduino-cli"
    go get -u github.com/arduino/arduino-cli
    cd ~/go/src/github.com/arduino/arduino-cli/

    echo "pin to latest version tag"
    git checkout tags/0.3.3-alpha.preview

    echo "update index of arduino cores"
    arduino-cli core update-index

    echo "install arduino core for avr and samd architectures"
    arduino-cli core install arduino:avr
    arduino-cli core install arduino:samd

    echo "download Arduino NB-IoT library"
    mkdir -p ~/Arduino/libraries
    cd ~/Arduino/libraries
    git clone https://github.com/ExploratoryEngineering/ArduinoNBIoT.git

    echo "symlink the protobuf library into Arduino libraries"
    ln -s ~/Arduino/nbiot-e2e/pb/nanopb ~/Arduino/libraries

    echo "build the arduino service that compiles and uploads sketches to the board(s) connected"
    cd ~/Arduino/nbiot-e2e/arduino-service
    go build

    echo "copy standard config for arduino-service to home dir"
    cp ~/Arduino/nbiot-e2e/arduino-service/.arduino-config.json ~/

    echo "install the arduino-service as a systemd service"
    sudo cp ~/Arduino/nbiot-e2e/arduino-service/arduino.service /etc/systemd/system/

    echo "enable and start arduino service"
    sudo systemctl start arduino.service
    sudo systemctl enable arduino.service
fi

echo "add scripts to crontab that poll git repos for changes"
# https://stackoverflow.com/questions/610839/how-can-i-programmatically-create-a-new-cron-job
(crontab -l ; echo -e "* * * * *\t/home/e2e/Arduino/nbiot-e2e/scripts/cron_e2e.sh") | sort - | uniq - | crontab -

if [ "$ENABLE_ARDUINO" = "1" ]; then
    (crontab -l ; echo -e "* * * * *\t/home/e2e/Arduino/nbiot-e2e/scripts/cron_arduino_nbiot.sh") | sort - | uniq - | crontab -
fi

echo "install AWS CloudWatch agent"
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -o /tmp/awslogs-agent-setup.py
# TODO move cloudwatch.conf to a file after PR merge
sudo tee /tmp/cloudwatch.conf <<EOL
#
# ------------------------------------------
# CLOUDWATCH LOGS AGENT CONFIGURATION FILE
# ------------------------------------------
#
# --- DESCRIPTION ---
# This file is used by the CloudWatch Logs Agent to specify what log data to send to the service and how.
# You can modify this file at any time to add, remove or change configuration.
#
# NOTE: A running agent must be stopped and restarted for configuration changes to take effect.
#
# --- CLOUDWATCH LOGS DOCUMENTATION ---
# https://aws.amazon.com/documentation/cloudwatch/
#
# --- CLOUDWATCH LOGS CONSOLE ---
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logs:
#
# --- AGENT COMMANDS ---
# To check or change the running status of the CloudWatch Logs Agent, use the following:
#
# To check running status: /etc/init.d/awslogs status
# To stop the agent: /etc/init.d/awslogs stop
# To start the agent: /etc/init.d/awslogs start
#
# --- AGENT LOG OUTPUT ---
# You can find logs for the agent in /var/log/awslogs.log
# You can find logs for the agent script in /var/log/awslogs-agent-setup.log
#

# ------------------------------------------
# CONFIGURATION DETAILS
# ------------------------------------------
# Refer to http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/AgentReference.html for details.

[general]
# Path to the CloudWatch Logs agent's state file. The agent uses this file to maintain
# client side state across its executions.
state_file = /var/awslogs/state/agent-state

[/var/log/syslog]
datetime_format = %b %d %H:%M:%S
file = /var/log/syslog
initial_position = start_of_file
log_group_name = /var/log/syslog
buffer_duration = 5000
log_stream_name = {hostname}

[/home/e2e/log/arduino-avr-uno.log]
datetime_format = %Y/%m/%d %H:%M:%S
file = /home/e2e/log/arduino-avr-uno.log
initial_position = start_of_file
log_group_name = /home/e2e/log/arduino-avr-uno.log
buffer_duration = 5000
log_stream_name = {hostname}

[/home/e2e/log/arduino-nbiot-lib.log]
datetime_format = %b %d %H:%M:%S
file = /home/e2e/log/arduino-nbiot-lib.log
initial_position = start_of_file
log_group_name = /home/e2e/log/arduino-nbiot-lib.log
buffer_duration = 5000
log_stream_name = {hostname}

[/home/e2e/log/nbiot-e2e.log]
datetime_format = %b %d %H:%M:%S
file = /home/e2e/log/nbiot-e2e.log
initial_position = start_of_file
log_group_name = /home/e2e/log/nbiot-e2e.log
buffer_duration = 5000
log_stream_name = {hostname}

[/home/e2e/log/nbiot-service.log]
datetime_format = %b %d %H:%M:%S
file = /home/e2e/log/nbiot-service.log
initial_position = start_of_file
log_group_name = /home/e2e/log/nbiot-service.log
buffer_duration = 5000
log_stream_name = {hostname}
EOL

sudo python3 /tmp/awslogs-agent-setup.py --region ${AWS_REGION} --non-interactive --configfile /tmp/cloudwatch.conf
sudo /etc/init.d/awslogs start

# create custom awslogs profile to avoid conflicts with ssm agent
sudo tee -a /root/.aws/credentials <<EOL
[awslogs]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOL
sudo tee -a /var/awslogs/etc/aws.conf <<EOL
[profile awslogs]
region = ${AWS_REGION}
EOL
sudo sed -i -e "s/ HOME/ AWS_PROFILE=awslogs HOME/" /var/awslogs/bin/awslogs-agent-launcher.sh

echo "create secure-tunnel service"
sudo tee -a /etc/systemd/system/secure-tunnel.service <<EOL
[Unit]
Description=Setup a secure tunnel to NB-IoT e2e server
After=network.target

[Service]
ExecStart=/usr/bin/ssh -v -NT -i /home/e2e/.ssh/id_rsa -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -R 2222:localhost:22 ubuntu@e2e.nbiot.engineering

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload

echo "delete pi user"
nohup sleep 5 && sudo deluser -remove-home pi &
