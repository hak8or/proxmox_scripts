#!/usr/bin/env bash

##########################
# Script to install Gogs, a Go based version control system.
##########################

# Header for this script
TITLE="Gogs_Setup"
LOGFILE=/tmp/$TITLE.log
DEPTH=2
if [[ $DEPTH == 0 ]]; then
    TAGSTR="-->"
elif [[ $DEPTH == 1 ]]; then
    TAGSTR="--->"
elif [[ $DEPTH == 2 ]]; then
    TAGSTR="----->"
elif [[ $DEPTH == 3 ]]; then
    TAGSTR="------>"
fi
echo "$TAGSTR ====== $TITLE (Logged to $LOGFILE) ======"

# All we need to do is install gogs and enable it. 
# Gogs configuration must be done via command line.
echo "$TAGSTR Installing Gogs"
yaourt -S gogs --noconfirm > $LOGFILE 2>&1
systemctl enable gogs > $LOGFILE 2>&1
systemctl start gogs > $LOGFILE 2>&1

# Lastly, say we are done.
echo "$TAGSTR Completed $TITLE"
