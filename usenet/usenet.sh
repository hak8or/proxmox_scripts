#!/usr/bin/env bash

##########################
# Script to install usenet utilities
#   - Sabnzb (usenet download client)
#   - Sonarr (Find and Manage TV Shows)
#   - Radarr (Find and Manage Movies)
##########################

# Header for this script
TITLE="Usenet_Setup"
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

# Install and config sabnzb.
echo "$TAGSTR Installing and configuring sabnzb"
yaourt -S sabnzbd python2-pyopenssl --noconfirm --needed > $LOGFILE 2>&1
cp /tmp/usenet/sabnzbd.ini /opt/sabnzbd/sabnzbd.ini

# Start sanbznd up
echo "$TAGSTR Starting sabnzb (default port: 8085)"
systemctl start sabnzbd
systemctl enable sabnzbd

# Install and config sonarr.
echo "$TAGSTR Installing and configuring sonarr"
yaourt -S libmediainfo mono sqlite sonarr --noconfirm --needed > $LOGFILE 2>&1
mkdir /usr/lib/sonarr
mkdir /var/lib/sonarr
tar -xzf /tmp/usenet/NzbDrone.tar.gz -C /tmp/usenet/ > $LOGFILE 2>&1
mv -f /tmp/usenet/NzbDrone/* /var/lib/sonarr
chown -R sonarr:sonarr /usr/lib/sonarr
chown -R sonarr:sonarr /var/lib/sonarr

# Start up Sonarr.
echo "$TAGSTR Starting sonarr (default port: 8989)"
systemctl start sonarr
systemctl enable sonarr

# Install Radarr
echo "$TAGSTR Installing and configuring radarr"
yaourt -S radarr --noconfirm --needed > $LOGFILE 2>&1

# Start up radarr.
echo "$TAGSTR Starting radarr (default port: 7878)"
systemctl start radarr
systemctl enable radarr

# Lastly, say we are done.
echo "$TAGSTR Completed $TITLE"