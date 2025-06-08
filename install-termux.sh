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

# 1. Update Termux & Install Packages
pkg update && pkg upgrade -y
pkg install -y proot proot-distro git curl wget

# 2. Install Ubuntu if not installed
if ! proot-distro list | grep -q "ubuntu"; then
    echo -e "${YELLOW}[+] Installing Ubuntu...${NC}"
    proot-distro install ubuntu
fi

# 3. Setup inside Ubuntu
proot-distro login ubuntu -- bash -c "
apt update && apt upgrade -y
apt install -y git build-essential automake autoconf libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev

cd ~
[ ! -d sugarmaker ] && git clone https://github.com/decryp2kanon/sugarmaker.git
cd sugarmaker
./autogen.sh
./configure CFLAGS='-Wall -O2 -fomit-frame-pointer'
make -j\$(nproc)
"

# 4. Create fullscreen launcher (styled like ccminer)
proot-distro login ubuntu -- bash -c "cat > \$HOME/sugarmaker-launcher.sh" << 'EOF'
#!/bin/bash

# COLORS
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG="$HOME/.sugarmaker_config"
LOG="testlog.log"
PID_FILE="miner.pid"
CLEARER_PID="clearer.pid"
AUTO_CLEAR_ENABLED=false

# Defaults
WALLET="sugar1qyqzq90ykjam7u9c0jw0qsjlauc57chhlaqq94w"
POOL="stratum+tcp://nomp.mofumofu.me:3391"
WORKER="default"
THREADS=$(nproc)
ALGO="YespowerSugar"

[[ -f \$CONFIG ]] && source \$CONFIG

save_config() {
cat > \$CONFIG <<EOL
WALLET="\$WALLET"
POOL="\$POOL"
WORKER="\$WORKER"
THREADS="\$THREADS"
ALGO="\$ALGO"
AUTO_CLEAR_ENABLED=\$AUTO_CLEAR_ENABLED
EOL
}

is_running() {
    [[ -f \$PID_FILE ]] && ps -p \$(cat \$PID_FILE) > /dev/null 2>&1
}

start_miner() {
    if is_running; then
        echo -e "\${YELLOW}Miner already running. Stop it first.\${NC}"; sleep 2; return
    fi
    cd \$HOME/sugarmaker || { echo -e "\${RED}Folder sugarmaker not found.\${NC}"; return; }
    echo -e "\${GREEN}⛏️ Starting mining...\${NC}"
    ./sugarmaker -a \$ALGO -o \$POOL -u \${WALLET}.\$WORKER -p x -t \$THREADS >> \$LOG 2>&1 &
    echo \$! > \$PID_FILE
    echo -e "\${YELLOW}Started with PID \$(cat \$PID_FILE)\${NC}"

    if \$AUTO_CLEAR_ENABLED; then
        ( while true; do sleep 300; > \$LOG; done ) & echo \$! > \$CLEARER_PID
    fi
    sleep 1
}

stop_miner() {
    if is_running; then
        kill \$(cat \$PID_FILE) 2>/dev/null && rm -f \$PID_FILE
        echo -e "\${RED}🛑 Miner stopped.\${NC}"
    else
        echo -e "\${YELLOW}⚠️ Miner not running.\${NC}"
    fi
    if [[ -f \$CLEARER_PID ]]; then
        kill \$(cat \$CLEARER_PID) 2>/dev/null && rm -f \$CLEARER_PID
    fi
    sleep 1
}

view_log() {
    if [[ -f \$LOG ]]; then
        echo -e "\${GREEN}Live log - press Ctrl+X then Q to exit...\${NC}"
        sleep 1; less +F \$LOG
    else
        echo -e "\${RED}❌ Log not found.\${NC}"
        sleep 2
    fi
}

toggle_auto_clear() {
    if \$AUTO_CLEAR_ENABLED; then
        AUTO_CLEAR_ENABLED=false
        [[ -f \$CLEARER_PID ]] && kill \$(cat \$CLEARER_PID) 2>/dev/null && rm -f \$CLEARER_PID
    else
        AUTO_CLEAR_ENABLED=true
        if is_running; then
            ( while true; do sleep 300; > \$LOG; done ) & echo \$! > \$CLEARER_PID
        fi
    fi
    save_config
}

# Launcher Menu
while true; do
    clear
    echo -e "\${CYAN}========= Sugarmaker Fullscreen Launcher =========\${NC}"
    echo -e "\${GREEN} Wallet    :\${YELLOW} \$WALLET"
    echo -e "\${GREEN} Pool      :\${YELLOW} \$POOL"
    echo -e "\${GREEN} Worker    :\${YELLOW} \$WORKER"
    echo -e "\${GREEN} Threads   :\${YELLOW} \$THREADS"
    echo -e "\${GREEN} Algorithm :\${YELLOW} \$ALGO"
    echo -e "\${GREEN} Auto-Clear Log :\${YELLOW} \$AUTO_CLEAR_ENABLED"
    echo -e "\${CYAN}==================================================\${NC}"
    echo -e "\${YELLOW}[1]\${NC} Change Wallet"
    echo -e "\${YELLOW}[2]\${NC} Change Pool"
    echo -e "\${YELLOW}[3]\${NC} Change Worker"
    echo -e "\${YELLOW}[4]\${NC} Change Threads"
    echo -e "\${YELLOW}[5]\${NC} Change Algorithm"
    echo -e "\${YELLOW}[6]\${NC} Start Mining"
    echo -e "\${YELLOW}[7]\${NC} Stop Mining"
    echo -e "\${YELLOW}[8]\${NC} View Log (live)"
    echo -e "\${YELLOW}[9]\${NC} Toggle Auto-Clear Log"
    echo -e "\${YELLOW}[0]\${NC} Exit"
    echo -ne "\${CYAN}Select [0-9]: \${NC}"
    read -r opt
    case \$opt in
        1) read -p "New wallet: " WALLET; save_config ;;
        2) read -p "New pool: " POOL; save_config ;;
        3) read -p "New worker: " WORKER; save_config ;;
        4) read -p "CPU threads: " THREADS; save_config ;;
        5) read -p "Algorithm: " ALGO; save_config ;;
        6) start_miner; read -p "ENTER to return..." ;;
        7) stop_miner; read -p "ENTER to return..." ;;
        8) view_log ;;
        9) toggle_auto_clear; echo -e "\${GREEN}Auto-clear set to \$AUTO_CLEAR_ENABLED\${NC}"; sleep 2 ;;
        0) stop_miner; echo -e "\${RED}Exiting...\${NC}"; exit 0 ;;
        *) echo -e "\${RED}Invalid option.\${NC}"; sleep 1 ;;
    esac
done
EOF

# 5. Make executable
proot-distro login ubuntu -- bash -c "chmod +x \$HOME/sugarmaker-launcher.sh"

# 6. Add alias in Ubuntu
proot-distro login ubuntu -- bash -c "echo 'alias sugarmaker=\"bash \$HOME/sugarmaker-launcher.sh\"' >> \$HOME/.bashrc"

# 7. Add global Termux alias
echo 'proot-distro login ubuntu -- bash ~/sugarmaker-launcher.sh' > ~/sugarmaker
chmod +x ~/sugarmaker
mv ~/sugarmaker /data/data/com.termux/files/usr/bin/sugarmaker

# 8. Done
echo -e "\n${CYAN}============================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Run anytime with: ${YELLOW}sugarmaker${NC}"
echo -e "${CYAN}============================================${NC}"
sleep 2
sugarmaker
