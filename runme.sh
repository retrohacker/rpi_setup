#!/bin/bash

URL=https://downloads.raspberrypi.org/raspbian_lite_latest.torrent

echo "killall transmission-cli" > end.sh
chmod +x end.sh

transmission-cli -g . -w . -f end.sh $URL
