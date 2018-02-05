#/bin/bash

clear
cd ~
echo "**********************************************************************"
echo "* Ubuntu 16.04 is the recommended opearting system for this install. *"
echo "*                                                                    *"
echo "* This script will install and configure your TinCoin masternode.  *"
echo "**********************************************************************"
echo && echo && echo
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!                                                 !"
echo "! Make sure you double check before hitting enter !"
echo "!                                                 !"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo && echo && echo
sleep 3

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Gather input from user
read -e -p "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h) : " key
if [[ "$key" == "" ]]; then
    echo "WARNING: No private key entered, exiting!!!"
    echo && exit
fi
read -e -p "Server IP Address : " ip
echo && echo "Pressing ENTER will use the default value for the next prompts."
echo && sleep 3
read -e -p "Add swap space? (Recommended) [Y/n] : " add_swap
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    read -e -p "Swap Size [2G] : " swap_size
    if [[ "$swap_size" == "" ]]; then
        swap_size="2G"
    fi
fi    
read -e -p "Install Fail2ban? (Recommended) [Y/n] : " install_fail2ban
read -e -p "Install UFW and configure ports? (Recommended) [Y/n] : " UFW

# Add swap if needed
if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
    if [ ! -f /swapfile ]; then
        echo && echo "Adding swap space..."
        sleep 3
        sudo fallocate -l $swap_size /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    else
        echo && echo "WARNING: Swap file detected, skipping add swap!"
        sleep 3
    fi
fi


# Add masternode group and user
sudo groupadd masternode
sudo useradd -m -g masternode masternode

# Update system 
echo && echo "Upgrading system..."
sleep 3
sudo apt-get -y update
sudo apt-get -y upgrade

# Install fail2ban if needed
if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
    echo && echo "Installing fail2ban..."
    sleep 3
    sudo apt-get -y install fail2ban
    sudo service fail2ban restart 
fi

# Install firewall if needed
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
    echo && echo "Installing UFW..."
    sleep 3
    sudo apt-get -y install ufw
    echo && echo "Configuring UFW..."
    sleep 3
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 9859/tcp
    echo "y" | sudo ufw enable
    echo && echo "Firewall installed and enabled!"
fi

# Download Tincoin and install
echo && echo "Downloading Tincoin"
sleep 3
sudo apt-get install git
wget -O tincoind https://github.com/oakey22/Tincoin-Masternode-Setup/blob/master/tincoind?raw=true
wget -O tincoin-cli https://github.com/oakey22/Tincoin-Masternode-Setup/blob/master/tincoin-cli?raw=true
sudo chmod +x tincoind
sudo chmod +x tincoin-cli 
sudo add-apt-repository -y ppa:bitcoin/bitcoin
sudo apt-get update
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y 
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y
sudo apt-get install libqrencode-dev -y
sudo mv tincoin{d,-cli} /usr/local/bin


# Create config for Tincoin
echo && echo "Configuring Tincoin"
sleep 3
rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo mkdir -p /home/masternode/.tincoincore
sudo touch /home/masternode/.tincoincore/tincoin.conf
echo '
rpcuser='$rpcuser'
rpcpassword='$rpcpassword'
rpcallowip=127.0.0.1
listen=1
server=1
daemon=0 # required for systemd
logtimestamps=1
maxconnections=256
externalip='$ip'
masternodeprivkey='$key'
masternode=1
' | sudo -E tee /home/masternode/.tincoincore/tincoin.conf
sudo chown -R masternode:masternode /home/masternode/.tincoincore

    #Create my.cnf
    
 echo '
rpcuser='$rpcuser'
rpcpassword='$rpcpassword'
externalip='$ip'
masternodeprivkey='$key'

' | sudo -E tee ~/.my.cnf >/dev/null 2>&1
sudo chmod 0600 ~/.my.cnf

# Setup systemd service
echo && echo "Starting Tincoin Daemon..."
sleep 3
sudo touch /etc/systemd/system/tincoind.service
echo '[Unit]
Description=tincoind
After=network.target

[Service]
Type=simple
User=masternode
WorkingDirectory=/home/masternode
ExecStart=/usr/local/bin/tincoind -conf=/home/masternode/.tincoincore/tincoin.conf -datadir=/home/masternode/.tincoincore
ExecStop=/usr/local/bin/tincoin-cli -conf=/home/masternode/.tincoincore/tincoin.conf -datadir=/home/masternode/.tincoincore stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
' | sudo -E tee /etc/systemd/system/tincoind.service
sudo systemctl enable tincoind
sudo systemctl start tincoind

# Download and install sentinel
echo && echo "Installing Sentinel..."
sleep 3
sudo apt-get -y install virtualenv python-pip
sudo git clone https://github.com/tincoinpay/sentinel /home/masternode/sentinel
cd /home/masternode/sentinel
sudo virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
export EDITOR=nano
(crontab -l -u masternode 2>/dev/null; echo '* * * * * cd /home/masternode/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1') | sudo crontab -u masternode -
sudo chown -R masternode:masternode /home/masternode/sentinel
cd ~


# Add alias to run tincoin-cli
echo && echo "Masternode setup complete!"
touch ~/.bash_aliases
echo "alias tincoin-cli='tincoin-cli -conf=/home/masternode/.tincoincore/tincoin.conf -datadir=/home/masternode/.tincoincore'" | tee -a ~/.bash_aliases

echo && echo "Now run 'source ~/.bash_aliases' (without quotes) to use tincoin-cli"
