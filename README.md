# Script to patch Jboss_EAP 6.*
===============================

## Features
------------

* Allows to Install patches on JbossEAP-6.*
* Use be used to install on multiple profiles (e.g. $JBOSS_HOME/<profiles1>, $JBOSS_HOME/<profile2>, etc.)
* Bash script using Jboss CLI to intract with Server.
* Instance should be down before executing script.
* It will start script only in admin-mode, so startup will be too fast.
* Parameters are: {-u [username] -w [password] -i [Instance-name] -j [Path-to-jbossinstal-dir] -p [Path-to-patch-file]}
* All logs(stdout and stderr) will be printed in $JBOSS_CONSOLE_LOG as well as on console for troubleshooting in case something went wrong. 

## How to use it
----------------

The script name is *jboss_eap_patch.sh* . Basically we are starting the instance in admin mode and then doing patching using Jboss CLI management. During execution you need to pass below parameters to script, otherwise it will fail.

- -u:		Username
- -w		Password
- -i		Server Profile name
- -j		Path to JBoss installation directory.
- -p		Path to JBoss EAP patch file.

```
Example : ./jboss_eap_patch.sh -u "username" -w "Password" -i <Instance-Name> -j <Path to JBOSS_HOME> -p <Path to Patch File> 
```
Within script we are shuting down instance after doing all changes. 

##Sample Output without any paramters:
      ```
      
      ./jboss_eap_patch.sh 
      Invalid instance: 
      No JBoss installation directory specified!
      No patch file specified!
      No JBoss profile specified!
      No Username specified!
      No Password specified!
      Usage: jboss_eap_patch.sh [args...]
      where args include:
      	-u		Username
      	-w		Password
      	-i		Server Profile name
      	-j		JBoss installation directory.
      	-p		JBoss EAP patch file.
      	
      ```
##Just Print Help message
      ```
      Usage: jboss_eap_patch.sh [args...]
      where args include:
      	-u		Username
      	-w		Password
      	-i		Server Profile name
      	-j		JBoss installation directory.
      	-p		JBoss EAP patch file.
    
      ```
  
Thanks!
