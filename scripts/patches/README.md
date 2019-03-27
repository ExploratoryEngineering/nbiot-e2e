# Raspberry pi patches

When we need to make changes to what is installed on the raspberry pis', we should avoid changing the existing setup script, since that won't update the already deployed pis'. Instead create a patch file that will install or modify the pi as needed.

The `cron_e2e.sh` is run every minute on the pis', and will run the `install_all.sh` every minute. By creating a patch as explained below, all you need is to update master on the nbiot-e2e repo to get the patch installed on all existing (and future) pis'. The once function will create a file with the same name as the script, but with the `.installed` file extention. When this file already exists, the patch won't be executed.

**Warning!** Do _not_ modify a patch that is already pushed to master and installed on the pis'. That will cause chaos. Create a new patch file instead. If the installation fails, the `.installed` file will not be created. Then you can modify the patch, but be aware that some parts of the script may have completed already. So be sure you know what you're doing.

**Another warning!** Try to avoid rebooting or exiting inside the function. If something went wrong, return an error code (`return` without arguments will pass the error of the previous command). Instead of rebooting, restart the related services. A patch that reboots will cause any remaining patches not to be installed until the next time master is updated.  This isn't an issue for running devices when we add patches one at a time, but it will be an issue when we create new devices, because they need to install all patches.  Consider augmenting the patch system to interpret a particular exit code as "needs reboot", and let the patch system do the reboot after all patches have been installed.

## Creating a patch file

1. Create a new bash script in `script/patches`
1. Make the file executable with `chmod`
1. Use this template to make sure it's only executed once:

        #!/bin/bash
        source ./once.sh

        function mypatch() {
            echo "Installing my patch"
            # do changes here
            
            # Avoid using exit - return instead.
            # return without arguments will return the status of the last command
            # executed in the function body.
            command_that_can_fail || return
        }

        once test

1. Add a line to `install_all.sh` where you execute the script
