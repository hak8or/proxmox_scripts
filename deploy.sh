#!/usr/bin/env bash

##########################
# Deploy script used for initilizing an Arch based container on Proxmox
# You should have cowsay installed because it's awesome!
##########################

# Header for this script
TITLE="Deployment_Script"
DEPTH=0
if [[ $DEPTH == 0 ]]; then
    TAGSTR="-->"
elif [[ $DEPTH == 1 ]]; then
    TAGSTR="--->"
elif [[ $DEPTH == 2 ]]; then
    TAGSTR="----->"
elif [[ $DEPTH == 3 ]]; then
    TAGSTR="------>"
fi
echo "====== $TITLE ======"

# IP address of the Proxmox host
PROXMOX_IP_ADDR=192.168.1.224
if [[ -z $PROXMOX_IP_ADDR ]]; then
    echo "$TAGSTR PROXMOX_IP_ADDR was not set!"
    exit
fi

# Verify we can talk to the proxmox host.
REPLYFROMSERVER=$(ssh root@$PROXMOX_IP_ADDR $"echo "Hello World"")
if [[ $REPLYFROMSERVER != "Hello World" ]]; then
    echo "$TAGSTR Failed to verify SSH connectivty with proxmox host."
    exit
fi

# Retrieve the IP address of a container as IPv4,IPv6. Arg1 is the container ID.
FN_get_IPaddr (){
    # IPv6 address fetch
    IPv6ADDR=$(ssh root@$PROXMOX_IP_ADDR "pct exec $1 ip addr show eth0 | grep /128 | grep -v fd75")
    IPv6ADDR=$(echo $IPv6ADDR | awk '{a=$2; split(a, b, "/"); print b[1]}')

    # IPv4 address fetch
    IPv4ADDR=$(ssh root@$PROXMOX_IP_ADDR "pct exec $1 ip addr show eth0 | grep inet")
    IPv4ADDR=$(echo $IPv4ADDR | awk '{a=$2; split(a, b, "/"); print b[1]}')
}

# Run a script on the the proxmox container. Arg 1 is container ID, arg 2 is script file.
# 
# This uses the proxmox host as a proxy, meaning it writes the script into the host, and
# then copies from proxmox to the guest, and executes on the guest. Only useful when you
# can't copy to script directly to the guest, like when ssh isn't running yet.
#
# Run script over SSH instead of using this when possible. For example:
# ssh root@$IPv6ADDR 'bash -s' < somescript.sh
FN_exec_script_proxy_container(){
    scp $2 root@$PROXMOX_IP_ADDR:/tmp/$2 > /dev/null

    ssh root@$PROXMOX_IP_ADDR /usr/bin/env bash <<- AcRP030Cclfad6
        pct push $1 /tmp/$2 /tmp/$2 > /dev/null
        pct exec $1 chmod +x /tmp/$2
        pct exec $1 /tmp/$2
AcRP030Cclfad6
}

# Runs a single script or copies the contents of a directory and executes a script that has
# the same name as the directory but with the .sh extension appended.
#
# Arg1 is the file name, Arg2 is the ip address.
FN_copyandorexec(){
    # Check if it's just a normal file (not directory).
    if [[ -f $1 ]]; then
        ssh root@$2 'bash -s' < $1
    fi

    # If it's a directory, copy the contents.
    if [[ -d $1 ]]; then
        # This may take a while, so let user know something is happening.
        echo "$TAGSTR Copying contents of $1"

        # Use Rsync in case it's many files.
        # Flag -a: Archive (recursive, copy symbolic links, modification times, etc)
        # Flag -z: Compress (use compression when sending)
        # Flag -e: specifies remote shell to use (to disable fingerprint verification)
        rsync -aze "ssh -q -o StrictHostKeyChecking=no" $1 root@[$2]:/tmp

        # Execute the presumed script inside the directory.
        ssh root@$2 "cd /tmp/$1; ./$1.sh"
    fi
}

# Check if we are referring to a specific container.
if [[ $1 == "-ID" ]]; then
    # Make sure we have a container ID
    if [[ -z $2 ]]; then
        echo "$TAGSTR No container ID was given!"
        exit
    fi

    # Get the machines IPv4 and IPv6 address.
    FN_get_IPaddr $2

    # Check if this is a snapshot operation
    if [[ $3 == "-snapshot" ]]; then
        # If no snapshot name given, abort.
        if [[ -z $4 ]]; then
            echo "$TAGSTR No snapshot name given!"
            exit
        fi

        # Check if the snapshot exists on proxmox for this VMID.
        SNAPSHOT_LIST=$(ssh root@$PROXMOX_IP_ADDR "pct listsnapshot $2")
        SNAPSHOT_LIST=$(echo "$SNAPSHOT_LIST" | awk '{print $1}' | grep $4)
        if [[ -z $SNAPSHOT_LIST ]]; then
            # Create a snapshot with this name.
            echo "$TAGSTR Creating a snapshot called $4 for VMID $2!"
            ssh root@$PROXMOX_IP_ADDR "pct snapshot $2 $4"
        else
            # Restore to the snapshot
            echo "$TAGSTR Rollbacking VMID $2 to snapshot $4!"
            ssh root@$PROXMOX_IP_ADDR "pct rollback $2 $4"

            echo "$TAGSTR Starting VMID $2!"
            ssh root@$PROXMOX_IP_ADDR "pct start $2"
        fi
        echo "$TAGSTR $IPv4ADDR, $IPv6ADDR"
        exit
    fi

    # Check if a script/dir was provided.
    if [[ -z $3 ]]; then
        # No script found, just return the ip address.
        echo "$IPv4ADDR, $IPv6ADDR"
        exit
    else
        # A script/dir was found, verify it exists.
        if [[ -e $3 ]]; then
            FN_copyandorexec $3 $IPv6ADDR
            echo "$TAGSTR $IPv4ADDR, $IPv6ADDR"
            exit
        else
            echo "$TAGSTR Directory or file $3 was not found."
            exit
        fi
    fi
fi

# Make sure SSH public key is in proxmox host. This overwrites if it exists.
scp $HOME/.ssh/id_rsa.pub root@$PROXMOX_IP_ADDR:/tmp/id_rsa.pub > /dev/null

# No specific container was provided, so we create one.
# Can pass small script like this: https://stackoverflow.com/a/3872762/516959
echo "$TAGSTR Creating container"
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

# Send and execute our arch init script.
FN_exec_script_proxy_container $VMID arch_setup.sh

# Get the IPv4 and IPv6 addresses of our noew container.
FN_get_IPaddr $VMID

# Wipe the fingerprint of the host in case it was used earlier.
ssh-keygen -R $IPv6ADDR > /dev/null

# Run any potential secondary script.
if [[ -n $1 ]]; then
    # A script was found, verify it exists.
    if [[ -e $1 ]]; then
        FN_copyandorexec $1 $IPv6ADDR
    else
        echo "$TAGSTR Directory or file $1 was not found."
        exit
    fi
fi

# Lastly, say we are done and what the IP address is to the terminal.
echo "$TAGSTR Completed $TITLE"
cowsay "Arch setup all done! VMID: $VMID, IPv4: $IPv4ADDR, IPv6: $IPv6ADDR"
