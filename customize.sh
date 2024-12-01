#!/bin/bash

# This script will be executed in a chroot.
# Write commands here as if you would run them within the final machine.
# $1 will be the disk reference of this template. Eg. '/dev/sdc'

# Adjust this script to add your customizations


export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# set timezone
echo Europe/Berlin > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
dpkg-reconfigure -f noninteractive tzdata


# Disable predictable network interface names ( https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/ )
# cat >> /etc/default/grub <<'HEREDOC'
# GRUB_CMDLINE_LINUX_DEFAULT="net.ifnames=0"
# HEREDOC

grub-mkconfig -o /boot/grub/grub.cfg
update-initramfs -u

# Don't fetch i18n
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations

# Add a custom mirror key
# curl https://example.com/myRepoKey.gpg | sudo apt-key add -

# Add a custom mirror:
#echo "deb     https://mirror.example.com/ubuntu noble custom" > /etc/apt/sources.list.d/myRepo.list
# apt-get update

# Grub really wants to install itself
debconf-set-selections <<DEBCONF
grub-pc grub-pc/install_devices_empty boolean true
DEBCONF

yes '' | apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc

# debootstrap doesn't pull in security updates
# Thats we we run updates once more
apt-get --yes dist-upgrade

# Grub really wants to install itself
debconf-set-selections <<DEBCONF
grub-pc grub-pc/install_devices_empty boolean false
DEBCONF

# add cloudinit to later deploy this image and the quemu-guest-agent
apt-get --yes install cloud-init qemu-guest-agent

# add whatever tools you want to have pre-installed on your image.
apt-get --yes install \
  sudo \
  build-essential \
  ethtool \
  htop \
  less \
  git \
  jq \
  dnsutils \
  mtr-tiny \
  nfs-common \
  vim \
  xfsprogs \
  xfsdump \
  xfslibs-dev \
  pciutils \
  resolvconf \
  update-notifier-common \
  wget \
  openssh-server

locale-gen "en_US.UTF-8"

# You should overwrite this password with cloudinit during deployment.
# This is really only for debugging in case cloudinit fails before setting a password
echo -e "changeme\nchangeme" | passwd root
