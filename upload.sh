#!/bin/bash

# This script is not meant to be used out of the box.
# It rather shows how a template COULD be uploaded
# The curl commands miss some authentication elements.
# Also the VM ID should be requested from the PVE API, instead of hardcoding one.
# This should be rewritten into


# Upload the image to Proxmox
scp *.qcow2 root@proxmox-node-1.example.com:/mnt/pve/myStorage/

# Create a new VM
curl -X POST "https://proxmox-node-1.example.com:8006/api2/json/nodes/MY_PROXMOX_NODE/qemu" \
-H "Authorization: PVEAPIToken=<API_TOKEN>" \
-H "Content-Type: application/json" \
-d '{
  "vmid": 999,  # Replace with an available VM ID. There is an API endpoint to fetch one
  "name": "myTemplate",  # Use your naming convention here
  "memory": 1024,
  "cores": 1,
  "sockets": 1,
  "net0": "virtio,bridge=vmbr0"
}'

# Attach the existing disk image (maybe this can be done during creation already?)
curl -X POST "https://proxmox-node-1.example.com:8006/api2/json/nodes/MY_PROXMOX_NODE/qemu/999/drive" \
-H "Authorization: PVEAPIToken=<API_TOKEN>" \
-H "Content-Type: application/json" \
-d '{
  "drive": {
    "file": "myStorage:<IMAGE NAME>",  # Adjust this to your storage and disk image name
    "format": "qcow2",
    "type": "disk"
  }
}'

# Convert VM to template
curl -X POST "https://proxmox-node-1.example.com:8006/api2/json/nodes/MY_PROXMOX_NODE/qemu/999/convert" \
-H "Authorization: PVEAPIToken=<API_TOKEN>" \
-H "Content-Type: application/json" \
-d '{
  "newid": 999,  # The ID for the new template (can be the same as the original VM ID)
  "name": "myTemplate"  # The name for the new template
}'
