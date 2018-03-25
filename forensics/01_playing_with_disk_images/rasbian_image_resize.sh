#!/usr/bin/env bash
# set -x
PART_SAVE_FILE="/tmp/partition_save_$(date +%s)"
ASSUMED_SECTOR_SIZE="512"
CMDARR=()
test "$(whoami)" == "root" && {
    sudo=""
} || {
    sudo="sudo"
}

header() {
    echo
    echo "================="
    echo "$*"
    echo "================="
}

usage() {
    echo "$*"
    cat <<EOF
Usage:
    $(basename $0) <device> (i.e. /dev/mmcblk0)

NOTE:
   ASSUMED DISK SECTOR SIZE IS: ${ASSUMED_SECTOR_SIZE}
   You'll need to run each of these commands manually, I won't actually make changes
   to your system

   This is meant to run on a relatively new Linux system
   Backup your stuff before you execute against a block device
   SERIOUSLY, back your stuff up before running any of the commands

   This is meant to run against a raspbian pi disto image that's on an already 
   on an SD card. 

   You can download the images here:
   https://www.raspberrypi.org/downloads/raspbian/
EOF
    exit -1
}

#=============================================
# BEGIN
#=============================================

dev="${1}"
# dev="/dev/mmcblk0"
test -z "${dev}" && usage "Missing device argument, try again"
test -b "${dev}" || usage "Invalid Block device"
test -f /sbin/resize2fs || usage "Missing resize binary: Make sure you have e2fsprogs installed!"

${sudo} sfdisk -d ${dev} > ${PART_SAVE_FILE}

ext4_part="$(lsblk -lf |& grep "$(basename ${dev}).*ext4" | awk '{print $1}')"
test -z "${ext4_part}" && usage "Error, couldn't extract the partition!"
block_size="$(${sudo} dumpe2fs /dev/${ext4_part} 2>/dev/null | grep '^Block size' | awk '{print $3}')"
# start_sector=$(${sudo} fdisk -l ${dev} | grep "${ext4_part}" | awk '{print $2}')
start_sector=$(cat ${PART_SAVE_FILE} | grep "${ext4_part}" | cut -d: -f2 | cut -d, -f1 | awk '{print $2}')
resize_min=$(${sudo} resize2fs -P /dev/${ext4_part} 2>/dev/null | grep '^Est' | awk -F ": " '{print $2}')
bytes_new="$(((${resize_min} * ${block_size}) + (${start_sector} * 512)))"
save_block_count="$(((${bytes_new} / ${block_size}) + 1))"

## Save my current partition state
header "Just in case..."
cat <<EOF
Your disk layout has been saved to the following file. 
To restore if something goes badly, issue the following command:

${sudo} sfdisk ${dev} < ${PART_SAVE_FILE}
EOF

## Show the command to do the resize
header "STEP 1: Resize the ext4 Filesystem"
cmd="${sudo} resize2fs /dev/${ext4_part} ${resize_min}"
CMDARR+=("${cmd}")
echo "${cmd}"

## single command to shrink the partition
header "STEP 2: Remove the original partition (dont worry that data doesn't go away)"
cmd="${sudo} parted --script ${dev} rm 2"
CMDARR+=("${cmd}")
echo "${cmd}"
header "STEP 3: Add resized partition"
cmd="${sudo} parted --script ${dev} mkpart primary ext4 ${start_sector}s ${bytes_new}B"
CMDARR+=("${cmd}")
echo "${cmd}"
header "STEP 4: Clone to image or anothe SD Card"
cmd="${sudo} dd status=progress if=${dev} bs=${block_size} count=${save_block_count} > destination_file.img"
CMDARR+=("${cmd}")
echo "${cmd}"
header "TL;DR oneshot"
for c in "${CMDARR[@]}"; do
    echo "${c}"
done

