# Proxmox Scripts

My collections of various scripts related to proxmox. These can be used to create a new master template based on arch, re-setup my "homelab" from scratch on a new proxmox machine, and other smaller helper scripts.

## Deploy Script

A small wrapper which generates an Arch Linux based container (by default) and then runs a optional script. Also can provide the IP address of a container created using the Arch setup script.

Note you must update the ```PROXMOX_IP_ADDR``` variable at the top of the script so the script knows where to SSH to. Also, this is intentionally configured such that the proxmox login is via ssh-key only. If you need to setup the SSH keys, instructions can be found [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2).

```bash
# Create a arch linux based container.
deploy.sh # Outputs a container ID when complete.

# Create an Arch Linux based container which then runs a script to init gogs.
deploy.sh gogs.sh

# Create a snapshot of a container and then restore to said snapshot.
deploy.sh -ID 101 -snapshot foo # Snapshot called foo was created.
deploy.sh -ID 101 -snapshot foo # Rolling back to snapshot foo.

# Just run a script to init gogs on an already existing container.
deploy.sh -ID 101 gogs.sh

# Copy the contents of a directory and run {directory}/{directory.sh}
deploy.sh -ID 101 ruby_server

# Get a comma seperated IPv4 and IPv6 address of a container.
deploy.sh -ID 101 # Outputs an IPv4 and IPv6 address seperated by a comma.
```

## Arch Setup Script

Proxmox includes a arch template but it doesn't have a SSH daemon running and is missing a decent number of packages I tend to need for pretty much all my projects. So here is a small script which does a decent bit of the seutp.

- Enables SSH
- Sets up keys and mirrorlist for pacman
- Installs yaourt, htop, vim, base-devel (gcc, strip, ...), and cowsay
- Displays the containers IPv4 and IPv6 addreses

The ```deploy.sh``` script calls this script by default.
