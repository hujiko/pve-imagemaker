# PVE Imagemaker

Proof-of-Concept to automatically create up-to-date ubuntu images to be deployed in Proxmox with Cloud-Init.

It does that by spawning a VirtualBox, using Vagrant to control it and debootstrap to prepare the image disk.

## Using it

Check `_run.sh` to see how it can be used. This example will build an Ubuntu Noble VM.
`make.sh` makes a new VM image, `customize.sh` is where stuff can be adjusted to customize your VM.

## Other Distributions

Currently some stuff is hardcoded and will only work for Ubuntu. It would be cool to have this also support Debian and CentOS (and maybe even more).
If you manage to get another OS work, please contribute to add support for them.

## Issues

As this uses VirtualBox, and VirtualBox relies on `/dev/vboxdrv`, which you can't set from within a Docker container.
If you run this on a VM, you need to enable nested virtualization.

## Uploading to Proxmox

Sadly ProxMox does not have an API that allows to upload files to any storage.

Either the storage needs to be mounted wherever the image id build (eg. NFS), or we need to use SSH / SCP to copy the disk image onto a Proxmox host.

Get inspried by `upload.sh` but be aware that this is rather an idea, and needs to be properly implemented. Ideally not in bash, but maybe ruby or python.
