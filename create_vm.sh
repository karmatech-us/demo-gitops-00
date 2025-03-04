#!/bin/bash


# --- Set environment variables ----------------------------------------------

set -e

export VM_NAME=ubu22-gitops1
echo "VM_NAME: $VM_NAME"
export IP_ADDR=192.168.122.41
echo "IP_ADDR: $IP_ADDR"
export MAC_ADDR=52:54:00:c3:9e:29
echo "MAC_ADDR: $MAC_ADDR"
export MEM=8192
export VCPUS=6

### IMPORTANT: 
### Change the following path to the correct path on your system
#
VM_CONFIG_ROOT=/home/iyusuf/projects/provision-machine/ubu-kvm/scripts/vm-configs/$VM_NAME
mkdir -p $VM_CONFIG_ROOT

#SOURCE_IMG_PATH=/var/lib/libvirt/images/ubuntu-22.04-server-cloudimg-amd64.img
SOURCE_IMG_PATH=/media/iyusuf/twotb/ventoy_isos/ubuntu-22.04-server-cloudimg-amd64.img
VIRTUAL_MACHINE_PATH=/var/lib/libvirt/images/$VM_NAME



# --- Write cloud-init files ------------------------------------------------

# Write meta-data
cat <<EOL > $VM_CONFIG_ROOT/meta-data
instance-id: $VM_NAME
local-hostname: $VM_NAME
EOL

# Write user-data
cat <<EOL > $VM_CONFIG_ROOT/user-data
#cloud-config
hostname: $VM_NAME
users:
  - default
  - name: iyusuf
    home: /home/iyusuf
    plain_text_passwd: 'dd'
    groups: users, admin
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-ed25519 XXXXXX_YOUR_SSH_PUB_KEY_XXXXX
ssh_pwauth: true
disable_root: false
EOL

# Write network-config
cat <<EOL > $VM_CONFIG_ROOT/network-config
ethernets:
    enp1s0:
        addresses: 
        - $IP_ADDR/24
        dhcp4: false
        routes:
          - to: 0.0.0.0/0
            via: 192.168.122.1
        match:
            macaddress: $MAC_ADDR
        nameservers:
            addresses:
            - 8.8.8.8
            - 1.1.1.1
        set-name: enp1s0
version: 2
EOL



# Organize vm by creating a vm folder in libvirt folder
sudo mkdir -p $VIRTUAL_MACHINE_PATH

# - Create a iso with user-data and meta-data files.
cloud-localds -v --network-config=${VM_CONFIG_ROOT}/network-config \
 ${VM_CONFIG_ROOT}/cloud-init.iso \
    ${VM_CONFIG_ROOT}/user-data \
    ${VM_CONFIG_ROOT}/meta-data 

# - Move the files
sudo mv ${VM_CONFIG_ROOT}/cloud-init.iso $VIRTUAL_MACHINE_PATH/

# Create disk
sudo qemu-img create -f qcow2 \
 -b $SOURCE_IMG_PATH -F qcow2 \
  $VIRTUAL_MACHINE_PATH/$VM_NAME.qcow2 5G

# - Change permissions
sudo chown libvirt-qemu:kvm $VIRTUAL_MACHINE_PATH/cloud-init.iso
sudo chown libvirt-qemu:kvm $VIRTUAL_MACHINE_PATH/$VM_NAME.qcow2




# --- Create the virtual machine ----------------------------------------------

virt-install \
  --name $VM_NAME \
  --memory ${MEM} \
  --vcpus ${VCPUS} \
  --import \
  --virt-type kvm \
  --disk path=$VIRTUAL_MACHINE_PATH/cloud-init.iso,device=cdrom \
  --disk path=$VIRTUAL_MACHINE_PATH/$VM_NAME.qcow2,format=qcow2 \
  --os-variant=ubuntu22.04 \
  --network network=default,model=virtio,mac=$MAC_ADDR \
  --graphics none \
  --console pty,target_type=serial

