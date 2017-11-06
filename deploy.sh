#!/usr/bin/env bash

##########################
# Deploy script used for initilizing an Arch based container on Proxmox
##########################

# Retrieve the IP address of a container as IPv4,IPv6
FN_get_IPaddr (){
    # IPv6 address fetch
    local IPv6ADDR=$(ssh root@$PROXMOX_IP_ADDR $"pct exec 101 ip addr show eth0 | grep /128 | grep -v fd75")
    IPv6ADDR=$(echo $IPv6ADDR | awk '{a=$2; split(a, b, "/"); print b[1]}')

    # IPv4 address fetch
    local IPv4ADDR=$(ssh root@$PROXMOX_IP_ADDR $"pct exec 101 ip addr show eth0 | grep inet")
    IPv4ADDR=$(echo $IPv4ADDR | awk '{a=$2; split(a, b, "/"); print b[1]}')

    # And return the address
    printf "%s,%s\n" $IPv4ADDR $IPv6ADDR
}

# IP address of the Proxmox host
PROXMOX_IP_ADDR=192.168.1.224
if [[ -z $PROXMOX_IP_ADDR ]]; then
    echo "PROXMOX_IP_ADDR was not set!"
    exit
fi

# Verify we can talk to the proxmox host.
REPLYFROMSERVER=$(ssh root@$PROXMOX_IP_ADDR $"echo "Hello World"")
if [[ $REPLYFROMSERVER != "Hello World" ]]; then
    echo "Failed to verify SSH connectivty with proxmox host."
    exit
fi

# Check if we are referring to a specific container.
if [[ $1 == "-ID" ]]; then
    # Make sure we have a container ID
    if [[ -z $2 ]]; then
        echo "No container ID was given!"
        exit
    fi

    # Check if a script was provided.
    if [[ -z $3 ]]; then
        # No script found, just return the ip address.
        FN_get_IPaddr $2
        exit
    else
        # A script was found, verify it exists.
        if [[ -e $3 ]]; then
            ssh root@$PROXMOX_IP_ADDR 'bash -s' < $3
            exit
        else
            echo "Bash script $3 was not found."
            exit
        fi
    fi
fi

# Make sure SSH public key is in proxmox host. This overwrites if it exists.
scp $HOME/.ssh/id_rsa.pub root@$PROXMOX_IP_ADDR:/tmp/id_rsa.pub > /dev/null

# No specific container was provided, so we create one.
# Can pass small script like this: https://stackoverflow.com/a/3872762/516959
VMID=$(ssh root@$PROXMOX_IP_ADDR /usr/bin/env bash <<-'AcRP030CAlfad6'
    # use the highest VMID+1 as our new VMID. This returns 1 if no VMID's exist.
    VMID=$(pct list | awk 'NR > 1 {print $1}' | sort -nr | head -n1)
    VMID=$(($VMID + 1))

    # VMID's less than 100 are for internal proxmox use, make sure we are >= 100.
    # This also could mean there were no proxmox boxes created.
    if [[ $VMID -lt 100 ]]; then
        VMID=100
    fi

    # Create a new container with the VMID
    pct create $VMID /var/lib/vz/template/cache/archlinux-base_20170704-1_amd64.tar.gz -ssh-public-keys /tmp/id_rsa.pub -storage local-zfs -net0 name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp -ostype archlinux > /dev/null

    # Start the container.
    pct start $VMID > /dev/null

    # And say all went well.
    echo "$VMID"
AcRP030CAlfad6
)
echo "Completed Container Init, ID: $VMID"

# Send our default arch init script over to proxmox host. This overwrites any old file.
scp arch_setup.sh root@$PROXMOX_IP_ADDR:/tmp/arch_setup.sh > /dev/null

# Copy the script into the container and run it.
ssh root@$PROXMOX_IP_ADDR /usr/bin/env bash <<- AcRP030CAlfad6
    pct push $VMID /tmp/arch_setup.sh /tmp/arch_setup.sh > /dev/null
    pct exec $VMID chmod +x /tmp/arch_setup.sh
    pct exec $VMID /tmp/arch_setup.sh
AcRP030CAlfad6

echo "Deploy.sh Complete!"
