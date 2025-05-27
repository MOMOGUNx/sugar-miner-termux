#!/data/data/com.termux/files/usr/bin/bash

# COLORS
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "============================================"
echo -e "${GREEN}Sugarmaker Miner Autoscript by MOMOGUNx${NC}"
echo "============================================"
echo -e "${NC}"

# 1. BASIC SETUP
pkg update && pkg upgrade -y
pkg install proot proot-distro git curl wget -y

# 2. INSTALL UBUNTU IF NOT PRESENT
if ! proot-distro list | grep -q "ubuntu"; then
    echo "[+] Installing Ubuntu..."
    proot-distro install ubuntu
fi

# 3. INSTALL DEPENDENCIES & SUGARMAKER IN UBUNTU
echo "[+] Setting up Sugarmaker in Ubuntu..."
proot-distro login ubuntu -- bash -c "
    apt update && apt upgrade -y &&
    apt install -y git build-essential automake autoconf libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev &&
    cd ~ &&
    if [ ! -d sugarmaker ]; then
      git clone https://github.com/decryp2kanon/sugarmaker.git
    fi &&
    cd sugarmaker &&
    ./autogen.sh &&
    ./configure CFLAGS='-Wall -O2 -fomit-frame-pointer' &&
    make -j\$(nproc)
"

# 4. CREATE LAUNCHER SCRIPT IN UBUNTU
proot-distro login ubuntu -- bash -c "cat > /root/sugarmaker-launcher.sh" <<'EOF'
#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG_FILE="/root/.sugarmaker_config"

# Default config
WALLET="sugar1qyqzq90ykjam7u9c0jw0qsjlauc57chhlaqq94w"
POOL="stratum+tcp://nomp.mofumofu.me:3391"
WORKER="default"
THREADS=$(nproc)
ALGO="YespowerSugar"

# Load existing config
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

save_config() {
    cat > "$CONFIG_FILE" <<EOL
WALLET="$WALLET"
POOL="$POOL"
WORKER="$WORKER"
THREADS="$THREADS"
ALGO="$ALGO"
EOL
}

while true; do
    clear
    echo -e "${CYAN}========== Sugarmaker Miner Menu ==========${NC}"
    echo -e "${GREEN} [Wallet Address]   :${YELLOW} $WALLET${NC}"
    echo -e "${GREEN} [Mining Pool]      :${YELLOW} $POOL${NC}"
    echo -e "${GREEN} [Worker Name]      :${YELLOW} $WORKER${NC}"
    echo -e "${GREEN} [CPU Threads]      :${YELLOW} $THREADS${NC}"
    echo -e "${GREEN} [Algorithm]        :${YELLOW} $ALGO${NC}"
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${YELLOW}[1]${NC} Change Wallet Address"
    echo -e "${YELLOW}[2]${NC} Change Mining Pool"
    echo -e "${YELLOW}[3]${NC} Change Worker Name"
    echo -e "${YELLOW}[4]${NC} Change CPU Threads"
    echo -e "${YELLOW}[5]${NC} Change Algorithm"
    echo -e "${YELLOW}[6]${NC} Start Mining"
    echo -e "${YELLOW}[7]${NC} Exit"
    echo -ne "${CYAN}Select an option [1-7]: ${NC}"
    read -r opt

    case $opt in
        1)
            echo -ne "${GREEN}Enter new wallet address: ${NC}"
            read -r WALLET
            save_config
            ;;
        2)
            echo -ne "${GREEN}Enter new mining pool URL: ${NC}"
            read -r POOL
            save_config
            ;;
        3)
            echo -ne "${GREEN}Enter new worker name: ${NC}"
            read -r WORKER
            save_config
            ;;
        4)
            echo -ne "${GREEN}Enter number of CPU threads: ${NC}"
            read -r THREADS
            save_config
            ;;
        5)
            echo -ne "${GREEN}Enter algorithm name (e.g., YespowerSugar): ${NC}"
            read -r ALGO
            save_config
            ;;
        6)
            echo -e "${GREEN}Starting mining...${NC}"
            cd ~/sugarmaker || exit
            ./sugarmaker -a "$ALGO" -o "$POOL" -u "$WALLET" -p "$WORKER" -t "$THREADS"
            read -p "Press ENTER to return to menu..."
            ;;
        7)
            echo -e "${RED}Exiting Sugarmaker Launcher.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose between 1 and 7.${NC}"
            sleep 1
            ;;
    esac
done
EOF

# 5. MAKE LAUNCHER EXECUTABLE
proot-distro login ubuntu -- bash -c "chmod +x /root/sugarmaker-launcher.sh"

# 6. CREATE ALIAS INSIDE UBUNTU
proot-distro login ubuntu -- bash -c "echo 'alias sugarmaker=\"bash /root/sugarmaker-launcher.sh\"' >> /root/.bashrc"

# 7. CREATE GLOBAL SHORTCUT FROM TERMUX
echo 'proot-distro login ubuntu -- bash /root/sugarmaker-launcher.sh' > ~/sugarmaker
chmod +x ~/sugarmaker
mv ~/sugarmaker /data/data/com.termux/files/usr/bin/sugarmaker

# 8. AUTO-LAUNCH INTO UBUNTU AND RUN SUGARMAKER
echo
echo -e "${CYAN}============================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Auto-starting Sugarmaker launcher..."
echo -e "Next time, just type: ${YELLOW}sugarmaker${NC}"
echo -e "${CYAN}============================================${NC}"
sleep 2
proot-distro login ubuntu -- bash /root/sugarmaker-launcher.sh
