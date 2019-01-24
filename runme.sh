#!/bin/bash

set -e

echo '================================================'
echo -n -e '\e[0;31m' # Red
echo ' ____  ____ ___   ____  _____ _____ _   _ ____  '
echo '|  _ \|  _ \_ _| / ___|| ____|_   _| | | |  _ \ '
echo '| |_) | |_) | |  \___ \|  _|   | | | | | | |_) |'
echo '|  _ <|  __/| |   ___) | |___  | | | |_| |  __/ '
echo '|_| \_\_|  |___| |____/|_____| |_|  \___/|_|    '
echo
echo -n -e '\e[0;37m' # White
echo '      Pi Image Generator by @retrohacker        '
echo -n -e '\e[0m' # Reset color
echo '================================================'
echo
echo -n -e '\e[0;31m' # Red
echo 'Downloading image...'
echo -n -e '\e[0m' # Reset color
echo

URL=https://downloads.raspberrypi.org/raspbian_lite_latest.torrent

echo "killall transmission-cli" > $PWD/end.sh
chmod +x $PWD/end.sh

# If we haven't downloaded a zip file, download it
if [ -z "`ls | grep '.*\.zip'`" ]
then
  transmission-cli -g . -w . -f $PWD/end.sh $URL || true
else
  echo "Already Downloaded"
fi

# If we haven't unzipped the image, do that
if [ -z "`ls | grep '.*\.img'`" ]
then
  unzip *.zip
else
  echo "Already Expanded"
fi

echo
echo -n -e '\e[0;31m' # Red
echo 'Setting up SSH and WiFi...'
echo -n -e '\e[0m' # Reset color
echo

BOOT_OFFSET=`sudo parted -m -s *.img unit b print | tail -n 2 | head -n 1 | cut -f 2 -d ':' | tr -d '[:alpha:]'`

mkdir -p boot root
sudo mount -o loop,offset=$BOOT_OFFSET *.img boot

# Turn on SSH
sudo touch boot/ssh
# Turn on WiFi
read -p 'WiFi ESSID: ' WIFI_ESSID
read -sp 'WiFi Password: ' WIFI_PASSWORD
echo ""

cat > wpa_supplicant.conf << EOF
network={
  ssid="$WIFI_ESSID"
  psk="$WIFI_PASSWORD"
}
EOF

sudo chown root:root wpa_supplicant.conf
sudo mv wpa_supplicant.conf boot/

sudo umount boot
sudo sync

ROOT_OFFSET=`sudo parted -m -s *.img unit b print | tail -n 1 | cut -f 2 -d ':' | tr -d '[:alpha:]'`

sudo mount -o loop,offset=$ROOT_OFFSET *.img root
echo
echo -n -e '\e[0;31m' # Red
echo 'Changing password for pi user...'
echo -n -e '\e[0m' # Reset color
echo

read -sp 'Pi Password: ' PI_PASSWORD
echo ""
SHADOW=`perl -e 'print crypt("'$PI_PASSWORD'", "\\$6\\$SBgOl43F\\$")'`

sudo sed -i "/pi:/d" root/etc/shadow
su -c "echo 'pi:$SHADOW:17848:0:99999:7::' >> root/etc/shadow"
sudo umount root

sudo sync

rm -rf boot root blocklists end.sh resume torrents

echo
echo '================================================'
echo -n -e '\e[0;31m' # Red
echo -n -e '\e[0m' # Reset color
echo "Generated $(ls *.img)"
echo '================================================'
