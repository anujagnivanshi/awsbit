
#-------------------------------------------------------------------------------
# Name:        create-snapshot-by-name-tag
# Purpose:             Calling python to create snapshots based in name tag
#
# Author:      Vijay Kumar P
#
# Created:     09/05/2016
# Copyright:   (c) test 2016 
#-------------------------------------------------------------------------------

#!/bin/env bash
if [ "$#" -ne 2 ];
then
                echo "Usage /usr/local/testbc/bin/create-snapshot-by-name.sh <regionName> <instanceName>"
                echo "Example: "
                echo "/usr/local/testbc/bin/create-snapshot-by-name.sh us-east-1 VkGenOVN1-testBCDB01Server"
                exit 1
else

regionName=$1
instanceName=$2


if ([ -n "${regionName}" ] && [ -n "${instanceName}" ]); then 
                    

python /usr/local/testbc/lib/standard/create-snapshots-by-name.py --region $1 --instanceName $2 > /usr/local/testbc/log/console-createsnapshot-by-name-tag.out 2>&1

                                
else echo "Please provide all inputs correctly";
fi
unset regionName
unset instanceName
fi