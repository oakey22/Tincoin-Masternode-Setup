# Tincoin-Masternode-Setup
Welcome to the Tincoin-Masternode-Setup wiki!

Please Donate to my TIN address if this has been useful to you.

tS2qa28ZHjkFxuLsxMJ2NDGeW5uEqL92C4

# Preperation

Get a VPS from a provider like OVH, DigitalOcean, Vultr, Linode, etc.

Recommended VPS size: 512mb or 1gb RAM

It must be Ubuntu 16.04 (Xenial) - 64bit

If using Vultr, use default settings.

Make sure you have a transaction of exactly 1000 TIN in your desktop cold wallet. This is done by sending yourself 1000 Tin in a single transaction.

# Cold Wallet Setup Part 1

Open your wallet on your desktop.

Go to the tab at the bottom that says "Tools"

Go to the tab at the top that says "Console"

Run the following command: masternode genkey

You should see a long key that starts with 7:

7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

This is your private key, keep it safe, do not share with anyone.

# VPS Setup

Log into your VPS

Copy command into the VPS command line and hit enter:

wget https://raw.githubusercontent.com/oakey22/Tincoin-Masternode-Setup/master/tincoin-install.sh && chmod +x tincoin-install.sh && ./tincoin-install.sh

When prompted, enter your private key from before.

You will be asked for your VPS IP and a few other questions.

The installation should finish successfully. Ask for help in discord if it doesn't.

# Cold Wallet Setup Part 2

Open your wallet on your desktop.

Go to the tab at the bottom that says "Tools"

Go to the tab at the top that says "Console"

Run the following command: masternode outputs

You should see output like the following if you have a transaction with exactly 1000 TIN: { "12345678xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx": "0" }

The value on the left is your txid and the right is the vout

Go the the tab at the bottom that says "Settings"

Click "Open Masternode Configuration File"

Add a line to the bottom of the file using the VPS IP (with port 9859), private key, txid and vout:

mn1 1.2.3.4:9859 7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 2345678xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 0

Save the file, exit your wallet and reopen your wallet.

Go to the tab at the bottom that says "Tools"

Go to the tab at the top that says "Console"

Run the command:

masternode start-alias mn1

Congratulations, your setup should now be complete! Ask for help in discord if you need.

You may see WATCHDOG_EXPIRED till the network picks up the node. This may take around 2 hours.

