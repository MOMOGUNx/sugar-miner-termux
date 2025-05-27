## Sugarmaker Miner Installer by MOMOGUNx 

This repository contains two installation scripts to set up the Sugarmaker cryptocurrency miner with an easy-to-use menu launcher:

Termux version — runs Ubuntu inside Termux on Android using proot-distro

Native Linux version — for Ubuntu/Debian desktop or server systems



---

## Features

** Installs all necessary dependencies

** Clones and builds Sugarmaker miner from official GitHub

** Provides an interactive menu to:

** Configure wallet address, pool, worker name, threads, and algorithm

** Start mining directly from the menu


** Creates a convenient launcher command sugarmaker for quick start



---

## Scripts Overview

1. Termux Installer (install-termux.sh)

** Runs on Android Termux environment

** Uses proot-distro to install and run Ubuntu inside Termux

** Install dependencies and Sugarmaker inside Ubuntu proot

** Creates a launcher script inside the Ubuntu environment

** Exposes sugarmaker command in Termux shell to start mining easily


2. Ubuntu/Debian Native Installer (install-linux.sh)

** Runs on Ubuntu or Debian systems directly

** Installs dependencies via apt

** Clones and builds Sugarmaker in user home directory

** Creates an interactive launcher script in home directory

** Adds a global command /usr/local/bin/sugarmaker for system-wide access



---


## For Termux (Android)

```bash

ufguhi
```

After completion, simply type:

```bash
sugarmaker
```

to open the miner menu and configure/start mining.




---

## For Ubuntu/Debian (Native Linux)

```bash
hdhajaja
```

After installation, run:

```bash
sugarmaker
```

from any terminal to start the miner menu.

---

## Miner Configuration Menu

** Change Wallet Address

** Change Mining Pool URL

** Change Worker Name

** Set CPU Thread Count

** Choose Algorithm (default: YespowerSugar)

** Start Mining with current settings

** Exit the menu


Settings are saved in ~/.sugarmaker_config and loaded automatically.


---

Notes

On Termux, the miner runs inside Ubuntu proot environment, so system requirements are limited by Android hardware.

On Ubuntu/Debian, the miner runs natively and can utilize full CPU power.

Make sure you have sufficient permissions and CPU cores available for mining.

Always use the latest wallet address and pool info for effective mining.


---

Support

If you find bugs or want to request features, please open an issue or contact telegram @MOMOGUNx.


---

Happy Mining!


---


