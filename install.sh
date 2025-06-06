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

# Load config jika ada
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
    cd "$HOME/sugarmaker" || exit
    ./sugarmaker -a "$ALGO" -o "$POOL" -u "$WALLET" -p "$WORKER" -t "$THREADS" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo -e "${YELLOW}Miner started with PID $(cat "$PID_FILE")${NC}"

    # Start auto-clear log setiap 5 minit
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
    if [[ -f "$PID_FILE" ]]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            echo -e "${RED}Stopped miner with PID $PID${NC}"
        else
            echo -e "${YELLOW}No running miner found.${NC}"
        fi
        rm -f "$PID_FILE"
    fi

    if [[ -f "$CLEARER_PID_FILE" ]]; then
        CLEAR_PID=$(cat "$CLEARER_PID_FILE")
        if ps -p "$CLEAR_PID" > /dev/null 2>&1; then
            kill "$CLEAR_PID"
            echo -e "${RED}Stopped auto log clearer.${NC}"
        fi
        rm -f "$CLEARER_PID_FILE"
    fi

    sleep 2
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
        1|2|3|4|5)
            if is_mining_active; then
                echo -e "${RED}❌ Stop the miner first before changing this setting.${NC}"
                sleep 2
            else
                case $opt in
                    1) echo -ne "${GREEN}Enter new wallet address: ${NC}"; read -r WALLET ;;
                    2) echo -ne "${GREEN}Enter new mining pool URL: ${NC}"; read -r POOL ;;
                    3) echo -ne "${GREEN}Enter new worker name: ${NC}"; read -r WORKER ;;
                    4) echo -ne "${GREEN}Enter number of CPU threads: ${NC}"; read -r THREADS ;;
                    5) echo -ne "${GREEN}Enter algorithm name (e.g., YespowerSugar): ${NC}"; read -r ALGO ;;
                esac
                save_config
            fi
            ;;
        6)
            start_mining
            read -p "Press ENTER to return to menu..."
            ;;
        7)
            stop_mining
            read -p "Press ENTER to return to menu..."
            ;;
        8)
            echo -e "${GREEN}Live miner log (press q to quit)...${NC}"
            sleep 1
            less +F "$LOG_FILE"
            read -p "Press ENTER to return to menu..."
            ;;
        9)
            stop_mining
            echo -e "${RED}Exiting Sugarmaker Launcher.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose between 1 and 9.${NC}"
            sleep 1
            ;;
    esac
done
EOF

# Make launcher executable
chmod +x ~/sugarmaker-launcher.sh

# Create alias in .bashrc instead of global link
if ! grep -q 'alias sugarmaker=' ~/.bashrc; then
  echo "alias sugarmaker='$HOME/sugarmaker-launcher.sh'" >> ~/.bashrc
fi

echo -e "${CYAN}============================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Run '${YELLOW}sugarmaker${NC}' command to start mining"
echo -e "Restart your terminal or run 'source ~/.bashrc' to enable alias"
echo -e "${CYAN}============================================${NC}"
