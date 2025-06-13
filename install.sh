#!/bin/bash

# COLORS
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================"
echo -e "${GREEN}Sugarmaker Miner Installer for Ubuntu/Debian"
echo -e "              by MOMOGUNx"
echo -e "${CYAN}============================================${NC}"

# Update and install dependencies
echo -e "${GREEN}[*] Installing dependencies...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y git build-essential automake autoconf libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev

# Clone Sugarmaker if not exists
cd ~
if [ ! -d "sugarmaker" ]; then
    echo -e "${GREEN}[*] Cloning Sugarmaker repository...${NC}"
    git clone https://github.com/decryp2kanon/sugarmaker.git
fi

# Build Sugarmaker
cd ~/sugarmaker
echo -e "${GREEN}[*] Building Sugarmaker...${NC}"
./autogen.sh
./configure CFLAGS='-Wall -O2 -fomit-frame-pointer'
make -j$(nproc)

# Create launcher script
cat > ~/sugarmaker-launcher.sh << 'EOF'
#!/bin/bash

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG_FILE="$HOME/.sugarmaker_config"
LOG_FILE="testlog.log"
PID_FILE="miner.pid"
CLEARER_PID_FILE="clearer.pid"

# Default config
WALLET="sugar1qyqzq90ykjam7u9c0jw0qsjlauc57chhlaqq94w"
POOL="stratum+tcp://nomp.mofumofu.me:3391"
WORKER="default"
THREADS=$(nproc)
ALGO="YespowerSugar"

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

save_config() {
    cat > "$CONFIG_FILE" <<EOL
WALLET="$WALLET"
POOL="$POOL"
WORKER="$WORKER"
THREADS="$THREADS"
ALGO="$ALGO"
EOL
}

is_mining_active() {
    [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1
}

start_mining() {
    if is_mining_active; then
        echo -e "${YELLOW}⚠️ Miner is already running with PID $(cat "$PID_FILE"). Stop it first.${NC}"
        sleep 2
        return
    fi

    echo -e "${GREEN}Starting mining...${NC}"
    cd "$HOME/sugarmaker" || { echo -e "${RED}❌ Directory sugarmaker not found.${NC}"; return; }

    ./sugarmaker -a "$ALGO" -o "$POOL" -u "${WALLET}.${WORKER}" -p x,sd=0.02,mindiff=5000 -t "$THREADS" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo -e "${YELLOW}⛏️ Miner started with PID $(cat "$PID_FILE")${NC}"

    (
        while true; do
            sleep 300
            > "$LOG_FILE"
        done
    ) &
    echo $! > "$CLEARER_PID_FILE"
    sleep 2
}

stop_mining() {
    if is_mining_active; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        echo -e "${RED}🛑 Miner stopped.${NC}"
        rm -f "$PID_FILE"
    else
        echo -e "${YELLOW}⚠️ Miner is not running.${NC}"
    fi

    if [[ -f "$CLEARER_PID_FILE" ]]; then
        kill "$(cat "$CLEARER_PID_FILE")" 2>/dev/null
        rm -f "$CLEARER_PID_FILE"
        echo -e "${RED}🧹 Auto log clearer stopped.${NC}"
    fi
    sleep 1
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
    echo -e "${YELLOW}[7]${NC} Stop Mining"
    echo -e "${YELLOW}[8]${NC} View Miner Log (live)"
    echo -e "${YELLOW}[9]${NC} Exit"
    echo -ne "${CYAN}Select an option [1-9]: ${NC}"
    read -r opt

    case $opt in
        1) [[ $(is_mining_active) ]] && echo -e "${RED}Stop mining first.${NC}" && sleep 2 || { echo -ne "${GREEN}Enter new wallet address: ${NC}"; read -r WALLET; save_config; } ;;
        2) [[ $(is_mining_active) ]] && echo -e "${RED}Stop mining first.${NC}" && sleep 2 || { echo -ne "${GREEN}Enter new pool URL: ${NC}"; read -r POOL; save_config; } ;;
        3) [[ $(is_mining_active) ]] && echo -e "${RED}Stop mining first.${NC}" && sleep 2 || { echo -ne "${GREEN}Enter new worker name: ${NC}"; read -r WORKER; save_config; } ;;
        4) [[ $(is_mining_active) ]] && echo -e "${RED}Stop mining first.${NC}" && sleep 2 || { echo -ne "${GREEN}Enter number of threads: ${NC}"; read -r THREADS; save_config; } ;;
        5) [[ $(is_mining_active) ]] && echo -e "${RED}Stop mining first.${NC}" && sleep 2 || { echo -ne "${GREEN}Enter algorithm (e.g., YespowerSugar): ${NC}"; read -r ALGO; save_config; } ;;
        6) start_mining; read -p "Press ENTER to return to menu..." ;;
        7) stop_mining; read -p "Press ENTER to return to menu..." ;;
        8) [[ -f "$LOG_FILE" ]] && less +F "$LOG_FILE" || echo -e "${RED}No log file found.${NC}"; read -p "Press ENTER to return..." ;;
        9) stop_mining; echo -e "${RED}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
    esac
done
EOF

# Make launcher executable
chmod +x ~/sugarmaker-launcher.sh

# Add alias to .bashrc if not already present
if ! grep -q 'alias sugarmaker=' ~/.bashrc; then
    echo "alias sugarmaker='$HOME/sugarmaker-launcher.sh'" >> ~/.bashrc
fi

echo -e "${CYAN}============================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Run '${YELLOW}sugarmaker${NC}' to start mining."
echo -e "Restart terminal or run '${YELLOW}source ~/.bashrc${NC}' to activate alias."
echo -e "${CYAN}============================================${NC}"
