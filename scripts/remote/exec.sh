#!/bin/bash -euf -o pipefail

: ${INSTANCE_ID:?"Missing INSTANCE_ID environment variable"}
CMD=$*
echo "Command to execute: $CMD"

command_id=$(aws ssm send-command --instance-ids "${INSTANCE_ID}" --document-name "AWS-RunShellScript" --comment "check authorized_keys" --parameters commands="$CMD" --output json | jq -r '.Command.CommandId')
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
