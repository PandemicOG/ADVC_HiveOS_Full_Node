#!/bin/bash

sleep 1

#### COLOR OUTPUT ####
cecho(){
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    YELLOW="\033[1;33m"
    CYAN="\033[1;36m"
    NC="\033[0m"
    printf "${!1}${2}${NC}\n"
}

cecho "YELLOW" "AdventureCoin Full Node Auto-Installer (HiveOS Edition)"
sleep 1

### DISK CHECK ###
cecho "YELLOW" "Checking available disk space..."
reqSpace=38000000
availSpace=$(df "$HOME" | awk 'NR==2 {print $4}')

if (( availSpace < reqSpace )); then
    cecho "RED" "Not enough disk space. Exiting..."
    exit 1
fi

cecho "GREEN" "Disk space OK. Continuing..."
sleep 1

### DEPENDENCIES ###
cecho "YELLOW" "Checking required packages..."

install_pkg() {
    if ! command -v "$1" >/dev/null 2>&1; then
        cecho "YELLOW" "Installing missing package: $1"
        apt-get update -y && apt-get install -y "$2"
    fi
}

install_pkg unzip unzip
install_pkg wget wget
install_pkg openssl openssl

### CREATE ADVC USER ###
if ! id "adventurecoin" >/dev/null 2>&1; then
    cecho "YELLOW" "Creating adventurecoin user..."
    adduser adventurecoin --system --group
else
    cecho "CYAN" "User already exists, continuing..."
fi

mkdir -p /usr/bin/adventurecoin.d
cd /tmp

### DOWNLOAD ADVC ###
cecho "YELLOW" "Downloading AdventureCoin Daemon..."
wget -q https://github.com/AdventureCoin-ADVC/AdventureCoin/releases/download/5.0.0.2-checkpoints/adventurecoin-x86_64-linux.zip

cecho "YELLOW" "Unzipping..."
unzip -oq adventurecoin-x86_64-linux.zip

if [ ! -d depends/x86_64-unknown-linux-gnu/bin ]; then
    cecho "RED" "ERROR: Binary folder not found. Stopping."
    exit 1
fi

cd depends/x86_64-unknown-linux-gnu/bin
chmod +x adventurecoind adventurecoin-cli
cp adventurecoind adventurecoin-cli /usr/bin/adventurecoin.d

ln -sf /usr/bin/adventurecoin.d/adventurecoin-cli /usr/bin/adventurecoin-cli
ln -sf /usr/bin/adventurecoin.d/adventurecoind /usr/bin/adventurecoind

### CONFIGURATION ###
cecho "YELLOW" "Setting up AdventureCoin config..."

RPCPASS=$(openssl rand -base64 41)

mkdir -p /var/lib/adventurecoin
cat <<EOF >/var/lib/adventurecoin/adventurecoin.conf
rpcuser=advcuser
rpcpassword=$RPCPASS
maxconnections=24
server=1
daemon=1
EOF

chown -R adventurecoin:adventurecoin /var/lib/adventurecoin

### RUNIT SERVICE (HiveOS) ###
cecho "YELLOW" "Creating HiveOS runit service..."

mkdir -p /etc/service/adventurecoind

cat <<'EOF' >/etc/service/adventurecoind/run
#!/bin/bash
exec 2>&1
exec chpst -u adventurecoin /usr/bin/adventurecoind -conf=/var/lib/adventurecoin/adventurecoin.conf -datadir=/var/lib/adventurecoin
EOF

chmod +x /etc/service/adventurecoind/run

### LOGGING ###
mkdir -p /var/log/adventurecoind
chmod 755 /var/log/adventurecoind

cat <<'EOF' >/etc/service/adventurecoind/log/run
#!/bin/bash
exec svlogd -tt /var/log/adventurecoind
EOF

chmod +x /etc/service/adventurecoind/log/run

### START SERVICE ###
cecho "GREEN" "Starting AdventureCoin service..."
sv restart adventurecoind || sv start adventurecoind

sleep 1

### DONE ###
cecho "GREEN" "AdventureCoin Node installation complete!"
cecho "CYAN"  "-------------------------------------------"
cecho "CYAN"  "Open your firewall & forward port 38817"
cecho "CYAN"  "-------------------------------------------"
sleep .5
ifconfig | grep -A 1 'eth0'
cecho "CYAN" "Use the IP listed above for port forwarding"
cecho "GREEN" "Node is now running under runit (HiveOS standard). Enjoy!"
