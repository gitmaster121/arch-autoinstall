#!/bin/bash
set -e

# Ustawienia
DISK="/dev/nvme0n1"
HOSTNAME="arch-hyper"
USERNAME="michal"
USERPASS="michal1212"
ROOTPASS="michal1212"
LOCALE="pl_PL.UTF-8"
TIMEZONE="Europe/Warsaw"

echo "[+] Partycjonowanie dysku ${DISK}..."
wipefs -af "$DISK"
sgdisk -Zo "$DISK"
sgdisk -n 1:0:+550M -t 1:ef00 -c 1:"EFI" "$DISK"
sgdisk -n 2:0:+55G -t 2:8300 -c 2:"ROOT" "$DISK"
sgdisk -n 3:0:0    -t 3:8300 -c 3:"HOME" "$DISK"

echo "[+] Formatowanie..."
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"
mkfs.ext4 "${DISK}p3"

echo "[+] Montowanie..."
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot /mnt/home
mount "${DISK}p1" /mnt/boot
mount "${DISK}p3" /mnt/home

echo "[+] Instalacja pakietów podstawowych..."
pacstrap /mnt base linux linux-firmware networkmanager sudo zsh bash grub efibootmgr intel-ucode vim

echo "[+] Generowanie fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[+] Konfiguracja systemu..."
arch-chroot /mnt /bin/bash <<EOF

echo "$HOSTNAME" > /etc/hostname
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo "KEYMAP=pl" > /etc/vconsole.conf

echo root:$ROOTPASS | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo $USERNAME:$USERPASS | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

systemctl enable NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "[✓] Instalacja zakończona! Możesz teraz zrestartować."
