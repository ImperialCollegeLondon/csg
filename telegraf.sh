#!/usr/bin/env bash
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

# Influxdb repo
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

# Install telegraf
try {
yum install telegraf -y
} catch { 	    
          echo "Could not install telegraf!"
          echo "Caught Exception:$(UI.Color.Red) $__BACKTRACE_COMMAND__ $(UI.Color.Default)"
	        echo "File: $__BACKTRACE_SOURCE__, Line: $__BACKTRACE_LINE__"

	        ## printing a caught exception couldn't be simpler, as it's stored in "${__EXCEPTION__[@]}"
	        Exception::PrintException "${__EXCEPTION__[@]}"
    }
# startup   
chkconfig telegraf on
