#!/bin/bash
set -f -o pipefail

pushd `dirname "$0"`
./nbiot_service.sh
# ./patch-thing.sh
# ./patch-another-thing.sh
popd
