#!/usr/bin/env bash

##########################
# Arch Linux initilizing script
##########################

# Header for this script
TITLE="Arch_Setup"
LOGFILE=/tmp/$TITLE.log
DEPTH=1
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

# For making the script stop if something fails like make.
set -e 
set -o pipefail

# Enable and start sshd so we can ssh in here in the future.
echo "$TAGSTR Enabling SSH"
systemctl enable sshd >> $LOGFILE 2>&1
systemctl start sshd >> $LOGFILE 2>&1

# Setup keys for pacman
echo "$TAGSTR Setting up keys for pacman"
pacman-key --init >> $LOGFILE 2>&1
pacman-key --populate archlinux >> $LOGFILE 2>&1

# Setup mirrors, hardcoded for now. Could have been done with rankmirror
# with USA and worldwide mirrors but eh.
echo "$TAGSTR Setting up mirror list"
if [[ -e /etc/pacman.d/mirrorlist ]]; then
	mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup # >> $LOGFILE 2>&1
fi
cat <<- 'EOM05594313219813' > /etc/pacman.d/mirrorlist
	# Server list generated by rankmirrors on 2017-11-03
	##
	## Arch Linux repository mirrorlist
	## Generated on 2017-06-28
	##
	## Worldwide
	## United States
	Server = http://mirror.nexcess.net/archlinux/$repo/os/$arch
	Server = http://mirror.epiphyte.network/archlinux/$repo/os/$arch
	Server = http://arch.mirror.constant.com/$repo/os/$arch
	Server = http://mirrors.evowise.com/archlinux/$repo/os/$arch
	Server = http://mirrors.advancedhosters.com/archlinux/$repo/os/$arch
	Server = http://mirror.math.princeton.edu/pub/archlinux/$repo/os/$arch
EOM05594313219813

# Update as needed.
echo "$TAGSTR Updating all packages as needed"
pacman -Syu --noconfirm --noprogressbar --needed >> $LOGFILE 2>&1

# Do an update and install some packages.
echo "$TAGSTR Installing base-devel, git, htop, vim, rsync, go, dotnet-sdk, wget, tmux, fish, and cowsay"
pacman -S base-devel git htop vim cowsay rsync go dotnet-sdk wget fish tmux --noconfirm --noprogressbar --needed >> $LOGFILE 2>&1

# Change locale to EN US UTF-8
echo "$TAGSTR Changing locale to EN US UTF-8"
sed -i 's/if (( EUID == 0 )); then/if (( 0 )); then/' /usr/bin/makepkg >> $LOGFILE 2>&1
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen >> $LOGFILE 2>&1
locale-gen >> $LOGFILE 2>&1
echo LANG=en_US.UTF-8 > /etc/locale.conf >> $LOGFILE 2>&1
export LANG=en_US.UTF-8

# Change our shell to fish
echo "$TAGSTR Changing shell to fish"
chsh -s /usr/bin/fish  >> $LOGFILE 2>&1

# Install yay. Why yay instead of pacaur? Because pacaur doesn't allow
# itself to be ran as root, even though all we have is root in the container,
# and I don't want to bother fiddling with users just for this. Yay on the
# other hand works fine for this.
if ! [ -x "$(command -v yay)" ]; then
	# Disable root check for makepkg since we are using root for everything.
	# Replace the "if (( EUID == 0 )); then" with "if (( 0 )); then" to force root
	# check to always fail.
	sed -i 's/if (( EUID == 0 )); then/if (( 0 )); then/' /usr/bin/makepkg >> $LOGFILE 2>&1

	echo "$TAGSTR Installing package-query and yay"
	mkdir ~/tmp
	cd ~/tmp
	# ----------- package query for yay -----------
	echo "$TAGSTR Installing package-query" >> $LOGFILE 
	git clone https://aur.archlinux.org/package-query.git >> $LOGFILE 2>&1
	cd package-query
	makepkg -si --noconfirm  >> $LOGFILE 2>&1
	cd ~/tmp
	# ----------- yay itself -----------
	echo "$TAGSTR Installing yay" >> $LOGFILE 
	git clone https://aur.archlinux.org/yay.git >> $LOGFILE 2>&1
	cd yay
	makepkg -si --noconfirm >> $LOGFILE 2>&1

	# Wipe tmp dir
	cd ~
	rm -r -f ~/tmp
fi

# Get the ip addresses using some grep and awk magic.
# Magic inspired by this: https://superuser.com/questions/468727/how-to-get-the-ipv6-ip-address-of-linux-machine
ipv6addr=$(ip addr show dev eth0 | grep "inet6 fe80" | awk '{a=$2; split(a, b, "/"); print b[1]}')
ipv4addr=$(ip addr show dev eth0 | grep "inet 10" | awk '{a=$2; split(a, b, "/"); print b[1]}')

# Lastly, say we are done.
echo "$TAGSTR Completed $TITLE"
echo "$TAGSTR Completed $TITLE" >> $LOGFILE 
