#!/bin/bash

# Define some variables
SSID="MyPiHotspot"
PASSPHRASE="raspberry"
IP_RANGE="192.168.4.50,192.168.4.150,12h"
AP_INTERFACE="wlan1"
ETH_INTERFACE="wlan1"  # Change to wlan1 if using Wi-Fi for internet
CONFIG_DIR="/etc/hostapd"
DNSMASQ_CONF="/etc/dnsmasq.conf"
HOSTAPD_CONF="$CONFIG_DIR/hostapd.conf"

# Stop hostapd and dnsmasq temporarily to make configuration changes
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Backup the original dnsmasq.conf
echo "Backing up original dnsmasq.conf..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

# Create new dnsmasq.conf
echo "Creating new dnsmasq.conf..."
sudo bash -c "cat > $DNSMASQ_CONF" <<EOF
interface=$AP_INTERFACE      # Use the wlan0 interface
dhcp-range=$IP_RANGE  # IP range for clients
EOF

# Configure hostapd (Access Point)
echo "Configuring hostapd..."
sudo mkdir -p $CONFIG_DIR
sudo bash -c "cat > $HOSTAPD_CONF" <<EOF
interface=$AP_INTERFACE
driver=nl80211
ssid=$SSID
hw_mode=g
channel=7
wpa=2
wpa_passphrase=$PASSPHRASE
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Enable IP forwarding by uncommenting the appropriate line in sysctl.conf
echo "Enabling IP forwarding..."
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# Apply the changes
sudo sysctl -p

# Set up NAT (Network Address Translation) to route traffic from clients to internet
echo "Configuring NAT..."
sudo iptables -t nat -A POSTROUTING -o $ETH_INTERFACE -j MASQUERADE
sudo iptables -A FORWARD -i $ETH_INTERFACE -o $AP_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $AP_INTERFACE -o $ETH_INTERFACE -j ACCEPT

# Save iptables rules
echo "Saving iptables rules..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Enable and start the services
echo "Enabling and starting hostapd and dnsmasq services..."
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
sudo systemctl start hostapd
sudo systemctl start dnsmasq

echo "Wi-Fi access point setup complete!"
echo "SSID: $SSID"
echo "Password: $PASSPHRASE"

