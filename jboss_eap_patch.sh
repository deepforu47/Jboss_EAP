#!/usr/bin/env bash
#
# Script that patches a JBoss EAP installation.
#
# This script expects EAP not to be running. If EAP is already running, this script will produce undefined results.
#
#Date-07Jul2016(Kuldeep Sharma)


#Specifiying the custom Instances. Replace with your own
VALID_INSTANCES=( node1 node2 node3 )

function contains_element() {
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
        #echo "in function $e";done
    return 1
}

# Source function library.
if [ -f /etc/init.d/functions ]
then
	. /etc/init.d/functions
fi

function usage {
      echo "Usage: jboss_eap_patch.sh [args...]"
      echo "where args include:"
      echo "	-u		Username"
      echo "	-w		Password"
      echo "	-i		Server Profile name"
      echo "	-j		JBoss installation directory."
      echo "	-p		JBoss EAP patch file."
}

#Parse the params
while getopts ":u:w:i:j:p:h" opt; do
  case $opt in
    u)
      user=$OPTARG
      ;;
    w)
      pass=$OPTARG
      ;;
    i) 
      INSTANCE=$OPTARG
      ;;
    j)
      JBOSS_INSTALLATION_DIR=$OPTARG
      ;;
    p)
      PATCH_FILE=$OPTARG 
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

for i in ${VALID_INSTANCES[@]}
do
        declare -a INSTANCES
        INSTANCES=("${INSTANCES[@]}" "`ls -dlm1 $JBOSS_INSTALLATION_DIR/*/ | awk -F"/" {'print $(NF-1)'} | grep -w $i`")
done

contains_element "${INSTANCE}" "${INSTANCES[@]}"
[[ ! "$?" -eq "0" && ! "${INSTANCE}" == "all" ]] && echo "Invalid instance: ${INSTANCE}"

PARAMS_NOT_OK=false

#Check params
if [ -z "$JBOSS_INSTALLATION_DIR" ] 
then
	echo "No JBoss installation directory specified!"
	PARAMS_NOT_OK=true
fi

if [ -z "$PATCH_FILE" ]
then
	echo "No patch file specified!"
	PARAMS_NOT_OK=true
fi
if [ -z "$INSTANCE" ]
then
        echo "No JBoss profile specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$user" ]
then
        echo "No Username specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$pass" ]
then
	echo "No Password specified!"
	PARAM_NOT_OK=true
fi
if $PARAMS_NOT_OK
then
	usage
	exit 1
fi

STARTUP_WAIT=30
# This is just a patch-script. W don't need an extensive console-log.
JBOSS_CONSOLE_LOG=$JBOSS_INSTALLATION_DIR/${INSTANCE}/log/console.log
JBOSS_SERVER_LOG=$JBOSS_INSTALLATION_DIR/${INSTANCE}/log/server.log

echo "Jboss Server Profile: $INSTANCE" | tee  -a $JBOSS_CONSOLE_LOG 2>&1
echo "Jboss Managment User: $user" | tee  -a $JBOSS_CONSOLE_LOG 2>&1
echo "JBoss installation directory: $JBOSS_INSTALLATION_DIR" | tee  -a $JBOSS_CONSOLE_LOG 2>&1
echo "Patch file: $PATCH_FILE" | tee  -a $JBOSS_CONSOLE_LOG 2>&1

# Start EAP in admin-only mode with the target profile
# Note that we're not checking whether a process is already running.
# We can use any profile we want when patching the installation.
#TODO: Add functionality to start JBoss EAP using the daemon function in RHEL/Linux.
echo "Starting JBoss EAP in 'admin-only' mode."  | tee  -a $JBOSS_CONSOLE_LOG 2>&1
$JBOSS_INSTALLATION_DIR/bin/standalone.sh -c standalone.xml -Djboss.server.base.dir=../$INSTANCE --admin-only  | tee -a $JBOSS_CONSOLE_LOG 2>&1 &

#Replace ports with what you have configured
if [[ $INSTANCE == node1 ]]; then
	port=10099
	elif [[ $INSTANCE == node2 ]]; then
		port=10199
		elif [[ $INSTANCE == node3 ]]; then
			port=10299
fi
echo "$INSTANCE:$port"
# Some wait code. Wait till the system is ready. Basically copied from the EAP .sh scripts.
count=0
launched=false

until [ $count -gt $STARTUP_WAIT ]
  do
    tail $JBOSS_SERVER_LOG | grep 'JBAS015874:' > /dev/null
    if [ $? -eq 0 ] ; then
      launched=true
      break
    fi
    sleep 1
    let count=$count+1;
  done
  
#Check that the platform has started, otherwise exit.

 if [ $launched = "false" ]
 then
	echo "JBoss EAP did not start correctly. Exiting."
	exit 1
else
	echo "JBoss EAP started."
fi

# Apply the patch
sleep 30
echo "Applying patch: $PATCH_FILE" | tee -a  $JBOSS_CONSOLE_LOG 2>&1
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh --user=$user --password="$pass" -c --controller=`hostname`:$port "patch apply $PATCH_FILE" | tee -a  $JBOSS_CONSOLE_LOG 2>&1

#Check for Patches
echo "Check for JBoss EAP Patches." | tee -a $JBOSS_CONSOLE_LOG 2>&1
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh --user=$user --password=$pass -c --controller=`hostname`:$port "patch info" 2>&1  | tee -a  $JBOSS_CONSOLE_LOG 2>&1

# And we can shutdown the system using the CLI.
echo "Shutting down JBoss EAP." | tee -a $JBOSS_CONSOLE_LOG 2>&1
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh --user=$user --password=$pass -c --controller=`hostname`:$port ":shutdown" 2>&1  | tee -a  $JBOSS_CONSOLE_LOG 2>&1

