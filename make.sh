#!/bin/bash

template=$1
name=$2

set -x
set -e

wd=$(mktemp -d /tmp/mkimg.XXXXXXXXXX)
export wd

(

mkdir -p $wd/mnt


#######################
##  Setup the disk  ###
#######################

# Find the disk
dev=$(ls /dev/disk/by-path/ | grep scsi-0:0:2:0$ | xargs -i readlink /dev/disk/by-path/{} | egrep -o "[a-z]+" | head -n 1)

echo /dev/$dev

# Partition the new disk. We create only one partition here.
echo "
mklabel gpt
mkpart primary 1 100%
name 1 ROOT
set 1 bios_grub on
q" | parted /dev/$dev

sleep 10

# Wait for the new partition to become available.
# We format it ti ext4 and mount it
for i in $(seq 1 5); do
  if [ -b /dev/${dev}1 ]; then
    mkfs.ext4 -L ROOT /dev/${dev}1
    mount -t ext4 /dev/${dev}1 $wd/mnt
    break
  else
    sleep ${i}
  fi
done


#######################
##  Install the OS  ###
#######################

# Install debbootstrap, which will be used to bootstrap our template
sudo apt-get update
sudo apt-get -y install debootstrap

# If you want to install custom packages, you can tell debbootstrap to trust a custom GPG-key:
# debbootstrap --keyring=/tmp/myMirror.gpg --include....
debootstrap --include=iproute2,iputils-ping,apt-transport-https,ca-certificates,linux-image-generic,grub-pc,curl,openssh-server,gnupg2,initramfs-tools --components=main,universe --arch=amd64 $template $wd/mnt https://mirror.wtnet.de/ubuntu

# Temporarily set a hostname. When deploying the image, you should use cloudinit to overwrite it.
echo "$(echo ${name} | sed 's/\//-/')" > $wd/mnt/etc/hostname

mount -t sysfs /sys $wd/mnt/sys
mount -t proc /proc $wd/mnt/proc
mount -o bind /dev $wd/mnt/dev
mount -o bind /dev/pts $wd/mnt/dev/pts

# Install the bootloader to make our disk bootable.
grub-install --root-directory=$wd/mnt /dev/${dev}

# Write an entry for the root disk to fstab
UUID=$(blkid ${1}1 -s UUID | awk -F'UUID="|"' '{print $2}')
echo -e "UUID=${UUID}\t/\text4\trw\t0\t0" > $wd/mnt/etc/fstab

# Write GRUB configuration
cat > $wd/mnt/etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR=Ubuntu
GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0"
GRUB_CMDLINE_LINUX=""
GRUB_DEVICE=/dev/disk/by-label/ROOT
EOF

# debbootstrap does not add security mirrors.
# You might want to run "apt update" in your customize.sh
echo "deb     https://mirror.wtnet.de/ubuntu ${template}-security main restricted universe multiverse" > /etc/apt/sources.list.d/Ubuntu_Security.list
echo "deb     https://mirror.wtnet.de/ubuntu ${template}-updates main restricted universe multiverse" > /etc/apt/sources.list.d/Ubuntu_Updates.list

########################
##  Customize Image  ###
########################

# In order to avoid writing chroot in front of every command,
# all steps that should run "from within the image" are placed in
# a separate file, that will be executed within a chroot.
chroot "${wd}/mnt" /bin/bash -ex < ./customize.sh -s -- "/dev/${dev}" $template $name
)
ecode=$?

set +e

umount $wd/mnt/proc
umount $wd/mnt/sys
umount $wd/mnt/dev/pts
umount $wd/mnt/dev
umount $wd/mnt
rm -rf $wd

exit $?
