# Playing with Disk Images / rasbian pi demo - [Video](https://youtu.be/xciV2fexJ1g)
## Explaination of what [rasbian_image_resize.sh](rasbian_image_resize.sh) does
### Get minimum block size resize2fs things is appropriate
* `resize2fs -P /dev/mmcblk0p2`
    * _*note*_ : gparted is bad at this for some reason. Might see if I can contribute

### Grab the block size
* `dumpe2fs /dev/${ext4_part} 2>/dev/null | grep '^Block size' | awk '{print $3}'`
    * Usually this is `4096`, but this command will grab that for you

### Grab the starting sector for the ext4 FS
* `fdisk -l /dev/mmcblk0`

```
/dev/mmcblk0p2      94208 7958527 7864320  3.8G 83 Linux
Disk /dev/mmcblk0: 3.8 GiB, 4075290624 bytes, 7959552 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xe73d5332

Device         Boot Start     End Sectors  Size Id Type
/dev/mmcblk0p1       8192   93596   85405 41.7M  c W95 FAT32 (LBA)
/dev/mmcblk0p2      94208 7958527 7864320  3.8G 83 Linux
```

* The important line is for parition 2 the start of `94208`

### Formula to get the disk end in bytes
* `(minimum_blocks * block_size) + (start_sector) * 512`
    * i.e. `(264940 * 4096) + (94208 * 512)` == `1133428736`

### Formula to get the number of blocks from the start of the disk to end
* `(end_bytes / block_size) + 1`
    * i.e. `(1133428736 / 4096) + 1` == `276716`
    * _if we don't add one it will give an error_

### Now we put it all together

```
sudo resize2fs /dev/mmcblk0p2 264940
sudo parted --script /dev/mmcblk0 rm 2
sudo parted --script /dev/mmcblk0 mkpart primary ext4 94208s 1133428736B
sudo dd status=progress if=/dev/mmcblk0 bs=4096 count=276717 > destination_file.img
```

# Links
* https://en.wikipedia.org/wiki/Disk_sector
