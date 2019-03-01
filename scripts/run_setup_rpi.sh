#!/bin/bash 

set -euf -o pipefail

# Check if pi is up and running with default hostname
if ! ping -c 1 -t1000 rasxpberrypi.local &> /dev/null
then
    echo "Error: Host raspberrypi.local not reachable"
    echo "Please make sure you're on the same network as the pi, and that the network has support for mDNS (Telenor_Skunk_Works wifi doesn't)."
    exit 1
fi

# SSM Activation codes
response=$(aws ssm create-activation --default-instance-name nbiot-e2e-pi --iam-role nbiot-e2e-pi --registration-limit 1 --region eu-west-1)
ssm_act_code=$(echo $response | jq -r '.ActivationCode')
ssm_act_id=$(echo $response | jq -r '.ActivationId')

# IAM access key
response=$(aws iam create-access-key --user-name nbiot-e2e-pi)
aws_access_key=$(echo $response | jq -r '.AccessKey.AccessKeyId')
aws_secret_key=$(echo $response | jq -r '.AccessKey.SecretAccessKey')

# GitHub Enterprise Personal access token
echo "Please enter a GitHub Enterprise Personal access token for ghe.telenordigital.com"
echo "If you haven't created it already, go to https://ghe.telenordigital.com/settings/tokens"
echo "and create a new one with «repo - Full control of private repositories»"
read -p "GHE Personal access token: " ghe_token

# Hostname
echo "What is the next available hostname?"
echo "Check here: https://eu-west-1.console.aws.amazon.com/systems-manager/managed-instances?region=eu-west-1"
echo "Enter the full hostname including nbiot-e2e-"
read -p "Next hostname number: " new_hostname

# Enable Arduino?
echo "Will the pi have an Arduino UNO with EE-NBIOT-01 connected?"
read -p "Enable Arduino? [0]" enable_arduino
enable_arduino=${enable_arduino:-0}

# Remove previously stored host identification key from known_hosts
sed '/raspberrypi\.local,/d' ~/.ssh/known_hosts > ~/.ssh/known_hosts

ssh pi@raspberrypi.local "NEWHOSTNAME=${new_hostname} \
        SSM_ACT_CODE=${ssm_act_code} \
        SSM_ACT_ID=${ssm_act_id}  \
        AWS_ACCESS_KEY=${aws_access_key} \
        AWS_SECRET_KEY=${aws_secret_key} \
        GHE_TOKEN=${ghe_token} \
        ENABLE_ARDUINO=${enable_arduino} \
        bash -s --" < setup_rpi.sh
