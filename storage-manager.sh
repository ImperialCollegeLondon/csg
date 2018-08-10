#!/usr/bin/env bash
#set -x
#set -e
source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/lib/oo-bootstrap.sh"
# load the type system
import util/log util/exception util/tryCatch util/namedParameters

# load the standard library for basic types and type the system
import util/class

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check to make sure script is running on CentOS/Redhat
if [ ! -f /etc/redhat-release ]; then
        echo "This script is for CentOS"
        exit
fi

# Install Storage Manager (SSM)
try {
	yum install system-storage-manager -y
} catch {
	    echo "Could not install Storage Manager!"
	    echo "Caught Exception:$(UI.Color.Red) $__BACKTRACE_COMMAND__ $(UI.Color.Default)"
	    echo "File: $__BACKTRACE_SOURCE__, Line: $__BACKTRACE_LINE__"

	    ## printing a caught exception couldn't be simpler, as it's stored in "${__EXCEPTION__[@]}"
	    Exception::PrintException "${__EXCEPTION__[@]}"
    }
    
# Show disk status
ssm list

# Print Example Config
echo to add /dev/sdb in a new pool and mount as /mnt/storage
echo ssm create -s 100% -n data --fstype xfs -p storage /dev/sdb /mnt/storage
