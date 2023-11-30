# ZANGSM (Zandronum Game Server Manager)

ZANGSM (Zandronum Game Server Manager) is designed to simplify the process of booting and logging multiple game servers. Supporting Zandronum, Q-Zandronum, Sonic Robo Blast 2 (SRB2), SRB2 Kart. The `zangsm.sh` script is 100% Shell and designed to run on Ubuntu. I have not tested any other distro. Architecture wise, the script is compatible with `x86_64` and `arm64`. A setup script `zangsmsetup.sh` is also provided automating the process of sourcing server binaries and dependencies for running these game servers.   

# Contents
- [Setup](#setup)
  - [zangsmsetup.sh](#zansetup)
- [Usage](#usage)
  - [zangsm.sh](#zangsm)
- [License](#license)

# Setup

To get ZANGSM standalone execute the following:
```bash
git clone https://github.com/blind-git/zangsm.git
cd ~/zangsm &&
sudo bash zangsmsetup.sh
```

## [zangsmsetup](https://github.com/blind-git/zangsm/blob/main/zangsmsetup.sh)

To install server files for x86_64 or arm64 architectures for Zandronum/Q-Zandronum/SRB2/SRB2Kart see the following options:

Usage: sudo bash zangsmsetup.sh [options] 

Options:
-a, -all        Install all available servers
-z, -zandronum  Install Zandronum
-q, -qzandronum Install QZandronum
-s, -srb2       Install SRB2
-k, -srb2kart   Install SRB2 Kart

You can modify the # Setup script to include the required options for your setup.

- Install server files into the `~/zangsm` dir. e.g. `zandronum-server` `zandronum.pk3` etc.

- Install IWADs to the `~/zangsm` folder as needed e.g. `doom2.wad` `heretic.wad` etc.

- Install PWADs in the `/zangsm/wads/` folder, supporting mod formats `.wad` `.pk3`

- Store server configs in the `/zangsm/cfgs/` directory with a `.cfg` extension.

- Note: Make new server configs from template configs to include all required variables for zangsm.

- Make sure to open ports on your vps host if applicable, and on your firewall.

# Usage

## [zangsm](https://github.com/blind-git/zangsm/blob/main/zangsm.sh)

Options: 
[-boot conf.cfg...] (Boot one or more servers)
[-list]             (Indexed list of active servers)
[-connect]          (Connect to a server session from list)
	- To detach from the session while leaving it running, press `Ctrl-b` followed by `d`.
	- To detach from session whilst terminating it, press 'Ctrl-d'.
[-kill]             (Kill a specific server from list)"
[-killall]          (Kill all servers)"