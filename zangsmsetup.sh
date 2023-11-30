#!/bin/bash                                  zansetup.sh#
#========================================================
zangsm=$(cat << "EOF" 
       _____   _    _   _  ____ ____  __  __
      |__  /  / \  | \ | |/ ___/ ___||  \/  |
        / /  / _ \ |  \| | |  _\___ \| |\/| |
       / /_ / ___ \| |\  | |_| |___) | |  | |
      /____/_/   \_\_| \_|\____|____/|_|  |_|

EOF
)
#========================================================
#                    ZANGSM-Setup                       #
#========================================================
echo "#========================================================"
echo "$zangsm" ; echo
echo "#========================================================"
echo "Setting up ZANGSM..."
# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "ZANGSM: Error - This script requires elevated privileges. Please run with sudo."
    exit 1
fi
echo "Setting permissions for zangsm.sh"
sudo chmod 755 ./zangsm.sh
# Global Declarations
architecture=$(arch)

# Function to add DRDTeam's Debian package repository and apply the GPG key
function add_drd(){
echo "Adding the DRDTeam's Debian package repository and applying the GPG key..." 
if sudo apt-add-repository --yes 'deb http://debian.drdteam.org/ stable multiverse'; then
    echo "Repository added successfully."
else
    echo "Error adding repository. Exiting."; exit 1
fi

if wget -O - http://debian.drdteam.org/drdteam.gpg | sudo apt-key add -; then
    echo "GPG key applied successfully."
else
    echo "Error applying GPG key. Exiting."; exit 1
fi
}

# Function to update package list and upgrade
function update_upgrade(){
if sudo apt-get update && sudo apt-get upgrade; then
    echo "Package list updated and upgraded successfully."
else
    echo "Error updating or upgrading packages. Exiting."; exit 1
fi
} 


# Function to install dependencies
function install_deps(){
if sudo apt-get install -y libsdl-image1.2 libjpeg62 libjpeg8; then
    echo "Dependencies installed successfully."
else
    echo "Error installing dependencies. Exiting."; exit 1
fi
}


# Function to install Zandronum server
install_zandronum() {
  echo "Installing Zandronum..."
  case $architecture in
  "x86_64"|"amd64")
    echo "Detected architecture: $architecture"
    # Install Zandronum x86_64 server files
    cd ~/zanboot &&
    echo "Downloading and extracting x86 Zandronum archives..."
    wget -N https://zandronum.com/downloads/testing/3.2/ZandroDev3.2-230709-1914linux-x86_64.tar.bz2
    tar -xjvf ZandroDev3.2-230709-1914linux-x86_64.tar.bz2
    ;;
  "aarch64"|"arm64")
    echo "Detected architecture: $architecture"
    # Source archives for arm64
    echo "Downloading and extracting arm64 Zandronum archives..."
    wget -N https://adhd.fearenough.com/wads/zandronum-arm64-serveronly-3.2a.tar
    
    ;;
  *)
    echo "Unsupported architecture: $architecture"
    exit 1
    ;;
esac
}

# Function to install Q-Zandronum server
install_qzandronum() {
  echo "Installing Q-Zandronum..."
  case $architecture in
  "x86_64"|"amd64")
    echo "Detected architecture: $architecture"
    # Install Q-Zandronum x86_64 server files
    echo "Downloading and extracting x86 Q-Zandronum archives..."
    wget -N https://github.com/IgeNiaI/Q-Zandronum/releases/download/1.4.10/Q-Zandronum_1.4.10_Linux_amd64.tar.gz
    tar -xzvf Q-Zandronum_1.4.10_Linux_amd64.tar.gz
    ;;
  "aarch64"|"arm64")
    echo "Detected architecture: $architecture"
    # Install Q-Zandronum arm64 server files
    echo "Downloading and extracting arm64 Q-Zandronum archives..."
    wget -N https://adhd.fearenough.com/wads/qzan-arm64-serveronly-1.4.11.tar
    tar -xvf qzan-arm64-serveronly-1.4.11.tar
    ;;
  *)
    echo "Unsupported architecture: $architecture"
    exit 1
    ;;
esac
}

# Function to install SRB2 server
install_srb2() {
  echo "Installing SRB2..."
  # Source server assets
  wget -N https://github.com/STJr/SRB2/releases/download/SRB2_release_2.2.13/SRB2-v2213-Full.zip
  unzip -o SRB2-v2213-Full.zip
  case $architecture in
  "x86_64"|"amd64")
    echo "Detected architecture: $architecture"
    wget -N https://git.do.srb2.org/STJr/SRB2/-/jobs/5426/artifacts/raw/bin/lsdl2srb2
    # Source binaries for amd64
    ;;
  "aarch64"|"arm64")
    echo "Detected architecture: $architecture"
    wget -N https://git.do.srb2.org/STJr/SRB2/-/jobs/5428/artifacts/raw/bin/lsdl2srb2
    # Source binaries for arm64
    ;;
  *)
    echo "Unsupported architecture: $architecture"
    exit 1
    ;;
esac
}

# Function to install SRB2-Kart server
install_srb2_kart() {
  echo "Installing SRB2-Kart..."
  # Source server assets
  wget -N https://github.com/STJr/Kart-Public/releases/download/v1.6/AssetsLinuxOnly.zip
  unzip -o AssetsLinuxOnly.zip
  case $architecture in
  "x86_64"|"amd64")
    echo "Detected architecture: $architecture"
    # Source binaries for amd64
    wget -N https://git.do.srb2.org/Alam/Kart-Public/-/jobs/6137/artifacts/file/bin/Linux64/Release/lsdl2srb2kart
    ;;
  "aarch64"|"arm64")
    echo "Detected architecture: $architecture"
    # Source binaries for arm64
    wget -N https://git.do.srb2.org/Alam/Kart-Public/-/jobs/6139/artifacts/raw/bin/Linux64/Release/lsdl2srb2kart
     ;;
  *)
    echo "Unsupported architecture: $architecture"
    exit 1
    ;;
esac
}
# Function to clean up archives
cleanup(){
# Prompt user if they want to remove the archives
read -p "Do you want to remove the server archives? (y/n): " remove_archives
if [ "$remove_archives" == "y" ]; then
  echo "Removing server archives..."
  rm ZandroDev3.2-230709-1914linux-x86_64.tar.bz2 Q-Zandronum_1.4.10_Linux_amd64.tar.gz
fi
}
add_drd
update_upgrade
install_deps

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a | -all)
            install_zandronum
            install_qzandronum
            install_srb2
            install_srb2_kart
            ;;
        -z | -zandronum)
            install_zandronum
            ;;
        -q | -qzandronum)
            install_qzandronum
            ;;
        -s | -srb2)
            install_srb2
            ;;
        -k | -srb2kart)
            install_srb2_kart
            ;;
        *)
            echo "ZANGSM: Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

echo "#========================================================"
echo "$zangsm" ; echo
echo "#========================================================"
echo "ZANGSM: Setup complete. Run bash zangsm.sh <option> <arg>"
echo "ZANGSM: Options [-boot conf.cfg...] (Boot one or more servers)"
echo "                [-list]             (List active servers)"
echo "                [-connect]          (Connect to a server session)"
echo "                [-kill]             (Kill a specific server)"
echo "                [-killall]          (Kill all servers)"
echo "#========================================================"
echo
#========================================================
# End of script                                         #
#========================================================
