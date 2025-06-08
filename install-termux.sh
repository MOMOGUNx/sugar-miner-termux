#!/data/data/com.termux/files/usr/bin/bash

# COLORS
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}============================================"
echo -e "${GREEN}Sugarmaker Miner Autoscript by MOMOGUNx${NC}"
echo -e "${CYAN}============================================${NC}"

# 1. INSTALL BASE PACKAGE
pkg update && pkg upgrade -y
pkg install proot proot-distro git curl wget -y

# 2. INSTALL UBUNTU IF NOT INSTALLED
if ! proot-distro list | grep -q "ubuntu"; then
    echo -e "${GREEN}[+] Installing Ubuntu...${NC}"
    proot-distro install ubuntu
fi

# 3. INSTALL DEPENDENCIES & BUILD SUGARMAKER
echo -e "${GREEN}[+] Setting up Sugarmaker in Ubuntu...${NC}"
proot-distro login ubuntu -- bash -c "
  apt update && apt upgrade -y && \
  apt install -y git build-essential automake autoconf libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev && \
  cd ~ && \
  if [ ! -d sugarmaker ]; then \
    git clone https://github.com/decryp2kanon/sugarmaker.git; \
  fi && \
  cd sugarmaker && \
  ./autogen.sh && ./configure CFLAGS='-Wall -O2 -fomit-frame-pointer' && \
  make -j\$(nproc)
"

# 4. CREATE LAUNCHER SCRIPT INSIDE UBUNTU
proot-distro login ubuntu -- bash -c "cat > /root/sugarmaker-launcher.sh" << 'EOF'
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

stop_mining() {
  if is_mining_active; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    echo -e "${RED}🛑 Miner stopped.${NC}"
  else
    echo -e "${YELLOW}⚠️ Miner is not running.${NC}"
  fi
  if [[ -f "$CLEARER_PID_FILE" ]]; then
    kill "$(cat "$CLEARER_PID_FILE")" 2>/dev/null
    rm -f "$CLEARER_PID_FILE"
  fi
  sleep 1
}

start_mining() {
  if is_mining_active; then
    echo -e "${YELLOW}⚠️ Miner is already running with PID $(cat "$PID_FILE"). Stop it first.${NC}"
    sleep 2
    return
  fi

  echo -e "${GREEN}Starting mining...${NC}"
  cd "$HOME/sugarmaker" || { echo -e "${RED}❌ Directory sugarmaker not found.${NC}"; return; }

  ./sugarmaker -a "$ALGO" -o "$POOL" -u "${WALLET}.${WORKER}" -p x -t "$THREADS" >> "$LOG_FILE" 2>&1 &
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

# MAIN MENU
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
    1) if is_mining_active; then echo -e "${RED}❌ Stop the miner first.${NC}"; sleep 2; else echo -ne "${GREEN}New wallet: ${NC}"; read -r WALLET; save_config; fi ;;
    2) if is_mining_active; then echo -e "${RED}❌ Stop the miner first.${NC}"; sleep 2; else echo -ne "${GREEN}New pool: ${NC}"; read -r POOL; save_config; fi ;;
    3) if is_mining_active; then echo -e "${RED}❌ Stop the miner first.${NC}"; sleep 2; else echo -ne "${GREEN}New worker name: ${NC}"; read -r WORKER; save_config; fi ;;
    4) if is_mining_active; then echo -e "${RED}❌ Stop the miner first.${NC}"; sleep 2; else echo -ne "${GREEN}Threads: ${NC}"; read -r THREADS; save_config; fi ;;
    5) if is_mining_active; then echo -e "${RED}❌ Stop the miner first.${NC}"; sleep 2; else echo -ne "${GREEN}Algorithm: ${NC}"; read -r ALGO; save_config; fi ;;
    6) start_mining; read -p "Press ENTER to return to menu..." ;;
    7) stop_mining; read -p "Press ENTER to return to menu..." ;;
    8) [[ -f "$LOG_FILE" ]] && echo -e "${GREEN}Live log (press q to quit)...${NC}" && sleep 1 && less +F "$LOG_FILE"; read -p "Press ENTER to return to menu..." ;;
    9) stop_mining; echo -e "${RED}Exiting...${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
  esac
done
EOF

# 5. MAKE THE LAUNCHER EXECUTABLE
proot-distro login ubuntu -- bash -c "chmod +x /root/sugarmaker-launcher.sh"

# 6. ADD ALIAS INSIDE UBUNTU
proot-distro login ubuntu -- bash -c "echo 'alias sugarmaker=\"bash /root/sugarmaker-launcher.sh\"' >> /root/.bashrc"

# 7. CREATE GLOBAL LAUNCHER FOR TERMUX
echo 'proot-distro login ubuntu -- bash /root/sugarmaker-launcher.sh' > ~/sugarmaker
chmod +x ~/sugarmaker
mv ~/sugarmaker /data/data/com.termux/files/usr/bin/sugarmaker

# 8. FINAL MESSAGE & AUTO-LAUNCH
echo -e "${CYAN}============================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Auto-starting Sugarmaker launcher..."
echo -e "Next time, just type: ${YELLOW}sugarmaker${NC}"
echo -e "${CYAN}============================================${NC}"
sleep 2
proot-distro login ubuntu -- bash /root/sugarmaker-launcher.sh
