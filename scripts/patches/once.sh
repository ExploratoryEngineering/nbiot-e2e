#!/bin/bash
set -f -o pipefail

function once() {
    fn=$1
    script=`basename "$0" | sed -e 's/\.sh//'`
    dir=`dirname "$0"`
    test_file="${dir}/${script}.installed"
    # echo "Patch: ${script}"
    
    if [ -e "$test_file" ]; then
        # echo "${script} installed already"
        exit 0
    fi

    ($fn && :) # run function without exiting on error
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        touch "$test_file"
        echo "${script} installed"
    else
        echo "Error installing patch: ${script}"
        echo "Exit code: ${exit_code}"
    fi
}
