#!/bin/bash
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e}
sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
sudo mkdir /etc/mdadm && touch /etc/mdadm/mdadm.conf
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
sudo parted -s /dev/md0 mklabel gpt
sudo parted /dev/md0 mkpart primary ext4 0% 25%
sudo parted /dev/md0 mkpart primary ext4 25% 50%
sudo parted /dev/md0 mkpart primary ext4 50% 75%
sudo parted /dev/md0 mkpart primary ext4 75% 100%
for i in $(seq 1 4); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4}
for i in $(seq 1 4); do mount /dev/md0p$i /raid/part$i; done