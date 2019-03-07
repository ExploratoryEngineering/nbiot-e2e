#!/bin/bash -euf -o pipefail

echo "Usage: $0 [hostname] command"

if [ $# -lt 1 ]; then
    echo "Not enough arguments"
    exit 1
fi

INSTANCE_ID=${INSTANCE_ID:-}
if [ ! -z "$INSTANCE_ID" ]; then
    instance_arg="--instance-ids ${INSTANCE_ID}"
else
    instance_arg=""
    pi=$1
    shift
fi

if [[ $pi != nbiot-e2e-* ]]; then
    echo "hostname has to be of form nbiot-e2e-XX"
    exit 1
fi

if [ -z "$INSTANCE_ID" ]; then
    INSTANCE_ID=$(aws ssm describe-instance-information --filters "Key=tag:Name,Values=${pi}" --max-items 1 | jq -r '.InstanceInformationList[0].InstanceId')
fi

cmd=$*
if [ -z "$cmd" ]; then
    echo "missing command argument"
    exit 1
fi

echo "Command to execute: $cmd"

tag_arg="--targets Key=tag:Name,Values=${pi}"

command_id=$(aws ssm send-command ${instance_arg} ${tag_arg} --document-name "AWS-RunShellScript" --comment "exec.sh" --parameters commands="$cmd" --output json | jq -r '.Command.CommandId')
echo $command_id
while true; do
    response=$(aws ssm get-command-invocation --command-id "$command_id" --instance-id "$INSTANCE_ID")
    response_code=$(echo $response | jq -r '.ResponseCode')
    status=$(echo $response | jq -r '.Status')
    
    if [ $response_code = "-1" ]; then
        echo "Waiting..."
        sleep 1
    elif [ $response_code = "0" ]; then
        echo STDOUT: $(echo $response | jq -r '.StandardOutputContent')
        echo STDERR: $(echo $response | jq -r '.StandardErrorContent')
        break
    elif [ $status = "Failed" ]; then
        echo STDOUT: $(echo $response | jq -r '.StandardOutputContent')
        echo STDERR: $(echo $response | jq -r '.StandardErrorContent')
        break
    else
        echo "Unknown status: $response_code"
        echo $response
        break
    fi
done
