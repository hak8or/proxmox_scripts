#!/usr/bin/bash

# To run this script, do the following:


# For making the script stop if something fails like make.
set -e 
set -o pipefail

# Enable and start sshd so we can ssh in here in the future.
echo "----> Enabling SSH"
systemctl enable sshd
systemctl start sshd

# Put my public SSH key in here.
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1NDs/5sOUhwwrCl7vbwl4gwn7HA071bwyrBYKaVM1pMkEj2e6BEfvm9dWuGF3tEUH3RQN8L9dQIuFUO+tDp99IJPVpkzXnhhuqsQp7GtSklqLg4fnJ9oop/w5PbUnDjS1jPNDssB8tmVeY3L/j9n/omZ0WkncYgQ9vlWVokkxg6fe0lYqv5e6VesWlzd4nPk63k9JcSF2/F06jgLFdSZhmV/DXHFNy8e1s+HHAWA3lhfIuCTNCZH4vFoOMucBjv858rxfBa+06YJ69JKP6aOHvbun7o1NQ9TSkNvPpYa/vr+Wf7Eu3t5A322D7w7zEBkCrNAiKbIgapbJQnailyO45TldjtxnQV99i6NU3Hyt0nuDfLPMQjYocwqcjykmZm+sTOgfYwVYDO+CmKIiCLpA1P6seJ2g0BL969bN2VgmHKYbX3obhVmRPGncTTYy3QJ72r1j5I30BtJkZk6X2uaFsQUgnPQutHBd6dpmP+lsWA10s4mDMNGWHl/IkS1ZdTlWETXiQh2N0iLQryUHynJGXKEkyrYUMRwm4BAJopcJiXXoPybeenhbmjai4jwEIvOkLUvesKl8lYJOcop174e6fN/ERypZLPweW6eQNipPHxeSkqqDpiPvQzaZEaVjucr1n5LqBBIcWZ7VZcioRNve06rsFt4aonkyEbORKlKIyQ== hak8or@gmail.com

# Setup keys for pacman
echo "----> Setting up keys for pacman"
pacman-key --init
pacman-key --populate archlinux

# Setup mirrors, hardcoded for now. Could have been done with rankmirror
# with USA and worldwide mirrors but eh.
echo "----> Setting up mirror list"
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
cat > /etc/pacman.d/mirrorlist <<-`EOM05594313219813`
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
`EOM05594313219813`

# Do an update to make sure all is, well, updated!
echo "----> Updating"
pacman -Syu --noconfirm

# Install git and base-devel which includes gcc and jazz.
echo "----> Installing base-devel and git"
pacman -S base-devel git --noconfirm

# Install Yaourt. Why yaourt instead of pacaur? Because pacaur doesn't allow
# itself to be ran as root, even though all we have is root in the container,
# and I don't want to bother fiddling with users just for this. Yaourt on the
# other hand works fine for this.
echo "----> Installing package-query and yaourt"
mkdir ~/tmp
cd ~/tmp
# ----------- package query for yaourt -----------
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -si
cd ..
# ----------- yaourt itself -----------
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -si
cd ..
cd ..
rm -r -f ~/tmp

# Install htop and cowsay cause they are awesome
echo "----> Installing htop and cowsay"
yaourt -S htop cowsay --noconfirm

# And say what the IP address is to the terminal.
cowsay "All Done!IP Address information: $(ip addr show)"

