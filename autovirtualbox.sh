#!/bin/sh
PROJECT_NAME=Chapter3
GUEST_USERNAME=chapter3
UBUNTU2004_ISO=${HOME}/Downloads/iso/ubuntu-20.04-desktop-amd64.iso
VM_LOCATION="${HOME}/Virtual VMs"
VBoxManage createvm --name ${PROJECT_NAME} --ostype Ubuntu_64 --register --basefolder "${VM_LOCATION}"
VBoxManage modifyvm ${PROJECT_NAME} --memory 8192 --vram 32
VBoxManage modifyvm ${PROJECT_NAME} --ioapic on
VBoxManage modifyvm ${PROJECT_NAME} --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm ${PROJECT_NAME} --cpus 2
VBoxManage modifyvm ${PROJECT_NAME} --nic1 nat
VBoxManage modifyvm ${PROJECT_NAME} --graphicscontroller vmsvga
VBoxManage modifyvm ${PROJECT_NAME} --usbohci on
VBoxManage modifyvm ${PROJECT_NAME} --draganddrop bidirectional
VBoxManage modifyvm ${PROJECT_NAME} --clipboard bidirectional
VBoxManage modifyvm ${PROJECT_NAME} --accelerate3d on

VBoxManage createmedium --filename "${VM_LOCATION}"/${PROJECT_NAME}/${PROJECT_NAME}.vdi --size 51200

VBoxManage storagectl ${PROJECT_NAME} --name IDE --add ide
VBoxManage storageattach ${PROJECT_NAME} --storagectl IDE --port 0 --device 0 --type dvddrive \
   --medium ${UBUNTU2004_ISO}

VBoxManage storagectl ${PROJECT_NAME} --name SATA --add SATA --controller IntelAhci --hostiocache on
VBoxManage storageattach ${PROJECT_NAME} --storagectl SATA --port 0 --device 0 --type hdd \
   --medium "${VM_LOCATION}"/${PROJECT_NAME}/${PROJECT_NAME}.vdi

VBoxManage unattended install ${PROJECT_NAME} \
   --user=${GUEST_USERNAME} \
   --password=${GUEST_USERNAME} \
   --country=US \
   --time-zone=MST \
   --iso=${UBUNTU2004_ISO} \
   --install-additions \
   --hostname=${PROJECT_NAME}.virtualbox.org \
   --start-vm=gui
