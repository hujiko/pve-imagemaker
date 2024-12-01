#!/bin/bash

while getopts ":t:n:d:h" opt; do
  case $opt in
    t)
      template=$OPTARG
      ;;
    n)
      name=$OPTARG
      ;;
    d)
      destroy=$OPTARG
      ;;
    h)
      echo ""
      echo "Use: build.sh [-t template] [-n name]"
      echo ""
      echo -e "Options:"
      echo -e "-h \t\t Show help message."
      echo -e "-t template\t Set template to build."
      echo -e "-n name\t\t Set template name."
      echo ""
      echo ""
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ -z "$template" ]; then
  echo "Option -t is required.";
  exit 1
fi

if [ -z "$name" ]; then
  echo "Option -n is required.";
  exit 1
fi

set -ex

# Don't get confused here.
# This is actually not the OS we want to have IN the template,
# This is the OS that is being used to BUILD the template.
# Jammy seems to be the newest available atm. Somehow noble does not exist yet.
# But we can build a noble template on a jammy box.
CODENAME=$(echo ${name} | sed 's/-.*//')
if [ "$(echo ${CODENAME} | sed 's/\/[0-9]//' | sed 's/[0-9]//')" == 'centos' ]; then
  BOXNAME=$(echo ${CODENAME} | sed 's/\/[0-9]//' | sed 's/[0-9]//')/$(echo ${CODENAME} | sed 's/\/[a-z]*//' | sed 's/[a-z]*//')
else
  BOXNAME="ubuntu/jammy64"
fi

DISK_IMAGE="$(pwd)/$(echo ${name} | sed 's/\//-/').vdi"
CODENAME=${CODENAME}
BOXNAME=${BOXNAME}
export DISK_IMAGE
export CODENAME
export BOXNAME

# In case the disk image already exists, we want to get rid of it.
# Ideally though you should supply a timestamp to your image name, so that
# you always know, which one is the latest.
test -f ${DISK_IMAGE} && vboxmanage closemedium disk ${DISK_IMAGE} --delete
rm -f ${DISK_IMAGE}

# This fails when BOXNAME was already downloaded in a previous run.
# But it does not matter. Maybe it would be cleaner to check for existance first, but: whatever :D
vagrant box add --provider virtualbox ${BOXNAME} || echo "latest box version of ${BOXNAME} already present"
vagrant up --provider virtualbox

# Execute the make.sh script to create the image.
vagrant ssh -c "cd /vagrant && sudo ./make.sh $template $name"
vagrant halt `echo $CODENAME | sed 's/\///g'`

# Proxmox does not like VDI disk images. Only RAW and QCOW2. I went for QCOW2 here:
# QCOW2:
#     PRO: - Supports snapshots
#     CON: - Not supported on LVM storage
qemu-img convert -f vdi -O qcow2 ${DISK_IMAGE} $(echo ${DISK_IMAGE} | sed 's/\.vdi/\.qcow2/g')

# We have our template disk image - we can now wipe the VM we used to create it.
vagrant destroy -f

# We don't need the VDI image, as we are only interested in the QCOW2
rm -f ${DISK_IMAGE}
