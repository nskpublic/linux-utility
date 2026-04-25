# Guide: Adding an External NTFS SSD to Jellyfin on Arch Linux
This guide summarizes how to permanently mount an external drive, fix common mounting errors, and correctly configure specific media folders.

## 1. Install Required Drivers
Arch Linux needs the ntfs-3g package to read and write to Windows-formatted (NTFS) drives.

```bash
sudo pacman -S ntfs-3g
```
**Use code with caution.**

## 2. Prepare the System
Create a static mount point. Avoid using /run/media/ as it is temporary and restricted.

```bash
sudo mkdir -p /mnt/jellyfin_media
```
**Use code with caution.**

## 3. Resolve "Can't open blockdev" or "Dirty" Errors
If the drive was not safely removed from Windows, it will be locked. Unmount it from the auto-generated path and repair the filesystem:

```bash
# Unmount if it was auto-mounted by the desktop
sudo umount /dev/sdb1

# Clear the NTFS "dirty" flag
sudo ntfsfix -d /dev/sdb1
```
**Use code with caution.**

## 4. Set Permissions

Jellyfin runs as the jellyfin user. It needs read and execute permissions on the mount point and all subfolders.
bash

### Mount the drive manually to verify
```bash
sudo mount /dev/sdb1 /mnt/jellyfin_media
```
### Apply permissions recursively
```bash
sudo chmod -R 755 /mnt/jellyfin_media
```
**Use code with caution.**

## 5. Permanent Mounting (Automount on Boot)

To ensure the drive is always there after a reboot, use the UUID (Unique ID) in your fstab file.

* Find the UUID:
```bash

lsblk -dno UUID /dev/sdb1
```
**Use code with caution.**

* Add to /etc/fstab:

Open the file with sudo nano /etc/fstab and add this line at the bottom:

```bash
UUID=YOUR_UUID_HERE  /mnt/jellyfin_media  ntfs-3g  defaults,nofail  0  0
```
**Use code with caution.**
(The nofail option ensures the PC still boots even if the SSD is unplugged.)

## 6. Jellyfin Web Configuration
To only show specific media and avoid scanning the whole disk:

* Navigate to Dashboard > Libraries > Libraries.
* Click the three dots (⋮) on your library icon.
* Select Manage Folders.
* Remove the root path /mnt/jellyfin_media.
* Add the specific path to your content, for example: /mnt/jellyfin_media/Movies.

**Note:** If you ever change the USB port and the drive doesn't show up, the UUID method in Step 5 will ensure it still mounts correctly.
