#!/usr/bin/env bash

##########################
# Script to install a small ruby based server.
# - Creates a webserver user and group for running ruby in
# - Uses bundler to handle dependancies
# - Puma since webrick doesn't doesn't bind to both IPv4 and IPv6 at the
#       same time due to a bug.
# - Creates systemd unit file for puma based ruby server.
# - Starts puma process when complete on port 9463
# - PATH put in .bash_profile so ruby works in non interactive login shell.
#
# To start the webserver.
#   systemctl start ruby_website
#
# To stop the webserver.
#   systemctl stop ruby_website
#
# To run bundle as website user on project.
#   su -l website -c 'cd /var/www && bundle install'
#
# To just run the ruby project manually without systemd
#   su -l website -c 'cd /var/www && bundle exec rackup -s puma -p 9463 -o [::]'
#
# You can also just change to the website user and do all your work in there.
#   su -l website
##########################

# Header for this script
TITLE="Ruby_Server_Setup"
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

# Get Ruby
echo "$TAGSTR Installing Ruby"
yaourt -S ruby --noconfirm > $LOGFILE 2>&1

# Change to website user since that's where all our gems and whatnot will exist.
groupadd website
useradd -m website -g website

# Create the /var/www directory which will hold our project.
mkdir /var/www

# Copy contents of source dir into better dir.
echo "$TAGSTR Copying from old dir into proper dir"
cp -r $PWD/* /var/www
chown -R website:website /var/www

# Copy over the systemd unit file of the website.
cp $PWD/ruby_website.service /lib/systemd/system

# Have Ruby in path by modfying bash sourced script.
BASHSCRIPT="/home/website/.bash_profile"
if [[ -e $BASHSCRIPT ]]; then
    # Append ruby path string to bash if such a line wasn't found.
    echo "$TAGSTR Appending to end of found bash_profile."
    grep -q -F "PATH=\"\$(ruby -e 'print Gem.user_dir')/bin:\$PATH\"" $BASHSCRIPT || echo "PATH=\"\$(ruby -e 'print Gem.user_dir')/bin:\$PATH\"" >> $BASHSCRIPT
    grep -q -F "PATH=\$PATH:\$HOME/.gem/bin" $BASHSCRIPT || echo "PATH=\$PATH:\$HOME/.gem/bin" >> $BASHSCRIPT
    grep -q -F "export GEM_HOME=\$HOME/.gem" $BASHSCRIPT || echo "export GEM_HOME=\$HOME/.gem" >> $BASHSCRIPT
    
else
    # File doesn't exist, so create it and add the ruby path.
    echo "$TAGSTR Creating new bash_profile."
    echo "PATH=\"\$(ruby -e 'print Gem.user_dir')/bin:\$PATH\"" > $BASHSCRIPT
    echo "PATH=\$PATH:\$HOME/.gem/bin" >> $BASHSCRIPT
    echo "export GEM_HOME=\$HOME/.gem" >> $BASHSCRIPT
fi

# Get bundler gem without documentation.
echo "$TAGSTR Fetching Bundler"
su -l website -c 'gem update --no-rdoc --no-ri' > $LOGFILE 2>&1
su -l website -c 'gem install bundler --no-rdoc --no-ri' > $LOGFILE 2>&1

# Install the website dependancies
echo "$TAGSTR Running bundle install to get all gems."
su -l website -c 'cd /var/www && bundle install' > $LOGFILE 2>&1

# Start up the website.
systemctl enable ruby_website > $LOGFILE 2>&1
systemctl start ruby_website  > $LOGFILE 2>&1

# Lastly, say we are done.
echo "$TAGSTR Completed $TITLE"
