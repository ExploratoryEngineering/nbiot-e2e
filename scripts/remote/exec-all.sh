#!/bin/bash -euf -o pipefail

CMD=$*
echo "Executing command on all pis': $CMD"
ts=$(aws ssm send-command --cloud-watch-output-config "CloudWatchLogGroupName=SSM-RunCommand-Output,CloudWatchOutputEnabled=true" --targets "Key=tag:Collection,Values=nbiot-e2e-pi" --document-name "AWS-RunShellScript" --parameters commands="$CMD" | sed 's/\.//g' | jq -r '.Command.RequestedDateTime')

while true; do
    response=$(aws logs filter-log-events --log-group-name SSM-RunCommand-Output --start-time "${ts}")
    length=$(jq '.events | length' <<< $response)
    if [[ $length -gt 0 ]]; then
        last_ts=$(jq '.events | max_by(.timestamp) | .timestamp' <<< $response)
        ts=$((last_ts + 1))
        jq -r '.events | .[].timestamp |= (. / 1000 | localtime | mktime | todate) | map("\(.timestamp)\t\(.logStreamName)\n\(.message)\n") | .[]' <<< $response
    fi
    sleep 1
done
