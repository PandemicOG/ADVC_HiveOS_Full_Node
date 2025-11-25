#!/bin/bash

sleep 1

#### COLOR SCRIPT
cecho(){
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    CYAN="\033[1;36m"
    PURPLE="\033[0;35m"
    WHITE="\033[0;37m"
    NC="\033[0m"

    printf "${!1}${2} ${NC}\n"
}
#### END COLOR SCRIPT


cecho "YELLOW" "     AdventureCoin Full Node Auto-Installer"
cecho "YELLOW" "     (Adapted from the Ravenpool installer)"
sleep 2


### DISK CHECK ###
cecho "YELLOW" "Checking available disk space..."
reqSpace=38000000
availSpace=$(df "$HOME" | awk 'NR==2 { print $4 }')

if (( availSpace < reqSpace )); then
    cecho "RED" "Not enough disk space. Exiting..."
    exit 1
fi

cecho "GREEN" "Disk space OK. Continuing..."
sleep 2

### CREATE ADVENTURECOIN USER ###
cecho "YELLOW" "Creating adventurecoin user..."
sleep 1
adduser adventurecoin --system --group

mkdir -p /usr/bin/adventurecoin.d
cd /tmp

### DOWNLOAD ADVENTURECOIN ###
cecho "YELLOW" "Downloading AdventureCoin daemon..."
wget -q https://github.com/AdventureCoin-ADVC/AdventureCoin/releases/download/5.0.0.2-checkpoints/adventurecoin-x86_64-linux.zip
sleep 3

cecho "YELLOW" "Unzipping files..."
unzip -oq adventurecoin-x86_64-linux.zip
sleep 2

cd depends/x86_64-unknown-linux-gnu/bin

chmod +x adventurecoind
chmod +x adventurecoin-cli

cp adventurecoind adventurecoin-cli /usr/bin/adventurecoin.d

ln -sf /usr/bin/adventurecoin.d/adventurecoin-cli /usr/bin/adventurecoin-cli
ln -sf /usr/bin/adventurecoin.d/adventurecoind /usr/bin/adventurecoind

### CONFIGURATION ###
echo -n 'rpcpassword=' > adventurecoin.conf
openssl rand -base64 41 >> adventurecoin.conf

cecho "YELLOW" "Setting up AdventureCoin directories..."
sleep 2

mkdir -p /root/.adventurecoin
cp adventurecoin.conf /root/.adventurecoin

mkdir -p /home/user/.adventurecoin
cp adventurecoin.conf /home/user/.adventurecoin

mkdir -p /etc/adventurecoin
echo 'maxconnections=24' >> adventurecoin.conf
cp adventurecoin.conf /etc/adventurecoin/adventurecoin.conf
chown adventurecoin:adventurecoin /etc/adventurecoin/adventurecoin.conf

mkdir -p /var/lib/adventurecoind
touch /var/lib/adventurecoind/adventurecoind.pid
chown -R adventurecoin:adventurecoin /var/lib/adventurecoind

### SYSTEMD SERVICE ###
cecho "YELLOW" "Downloading systemd service..."
cd /etc/systemd/system
wget -q https://raw.githubusercontent.com/AdventureCoin-ADVC/AdventureCoin/main/adventurecoind.service   # UPDATE IF DIFFERENT

cecho "YELLOW" "Enabling service..."
systemctl daemon-reload
systemctl enable adventurecoind.service
systemctl start adventurecoind.service

### DONE ###
cecho "GREEN" "AdventureCoin node installation complete!"
sleep 1
cecho "CYAN" "--------------------------------------"
cecho "CYAN" "Open your firewall & forward port 38817"
cecho "CYAN" "--------------------------------------"
sleep .5

ifconfig | grep -A 1 'wlan0'
ifconfig | grep -A 1 'eth0'

cecho "CYAN" "Use the IP listed above for port forwarding"
sleep .5
cecho "GREEN" "All finished. Enjoy your AdventureCoin node!"
