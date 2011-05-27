#!/usr/bin/env bash

umount /dev/loop0
losetup -d /dev/loop0
losetup -d /dev/loop1
losetup -d /dev/loop2
losetup -d /dev/loop3
losetup -d /dev/loop4
losetup -d /dev/loop5
losetup -d /dev/loop6
losetup -d /dev/loop7


# Uncomment to have to create all images again

rm -rf /data0/CN*
rm -rf /data0/images/*
rm -rf /data/internal/.loops
