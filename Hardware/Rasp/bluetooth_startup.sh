#!/bin/bash

# Enable Bluetooth and make it discoverable
bluetoothctl << EOF
power on
discoverable on
pairable on
agent NoInputNoOutput
default-agent
pair 54:10:4F:EE:A3:CE
EOF

echo "Bluetooth is now discoverable and ready for pairing."

