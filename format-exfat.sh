#!/bin/bash

# Safeguard: Run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

echo "==== Available Disks ===="
lsblk -d -o NAME,SIZE,MODEL

read -rp "Enter the device name to format (e.g., sda): " DEV_NAME
TARGET="/dev/$DEV_NAME"

# Confirm the device exists
if [ ! -b "$TARGET" ]; then
    echo "Error: $TARGET is not a valid block device."
    exit 1
fi

echo "You are about to ERASE and FORMAT $TARGET"
read -rp "Are you absolutely sure? Type 'YES' to continue: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo "=== Unmounting any mounted partitions..."
umount "${TARGET}"* 2>/dev/null

echo "=== Wiping old partition table..."
wipefs -a "$TARGET"

# Check for GPT issues and attempt to fix them using gdisk
echo "=== Checking and fixing GPT table (if necessary)..."
echo -e "r\nh\nw\ny\n" | gdisk "$TARGET" > /dev/null 2>&1

echo "=== Creating new GPT partition table..."
parted "$TARGET" --script mklabel gpt

echo "=== Creating full-size primary partition..."
parted -a optimal "$TARGET" --script mkpart primary 0% 100%

sleep 2  # Wait for system to recognize new partition

PART="${TARGET}1"
echo "=== Formatting $PART as exFAT..."
mkfs.exfat -n SSD_31TB "$PART"

echo "=== Verifying new partition..."
lsblk -f "$TARGET"

echo "✅ Done! $PART is now formatted as exFAT and ready for use."
