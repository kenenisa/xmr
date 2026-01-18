#!/bin/bash

# --- CONFIG ---
XMRIG_DIR="$HOME/xm/xmrig"
WALLET="491wvnyJWimjAxXsTHNdkF5vV1fTPcdFsZxmyLQnnGDA5QTf2UQVxxAGuM6QHcEFX3QqQUFsxDTjvRc8LSkU2AU81nSfeSk"
POOL="pool.supportxmr.com:3333"
THREADS=$(sysctl -n hw.ncpu 2>/dev/null || nproc)
SERVICE_NAME="xmrig"
echo "$THREADS"

# --- INSTALL DEPENDENCIES ---
sudo apt update
sudo apt install -y git build-essential cmake libuv1-dev libssl-dev libhwloc-dev

# --- CLONE AND BUILD XMRig ---
if [ ! -d "$XMRIG_DIR" ]; then
  git clone https://github.com/xmrig/xmrig.git "$XMRIG_DIR"
fi

cd "$XMRIG_DIR"
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# --- CREATE CONFIG.JSON ---
cat >config.json <<EOL
{
  "autosave": true,
  "cpu": {
    "enabled": true,
    "hw-aes": true,
    "priority": null,
    "asm": true,
    "max-threads-hint": $THREADS
  },
  "pools": [
    {
      "url": "$POOL",
      "user": "$WALLET",
      "pass": "$HOSTNAME",
      "keepalive": true,
      "tls": false
    }
  ]
}
EOL

# --- CREATE SYSTEMD SERVICE ---
sudo tee /etc/systemd/system/$SERVICE_NAME.service >/dev/null <<EOL
[Unit]
Description=XMRig
After=network.target

[Service]
ExecStart=$XMRIG_DIR/build/xmrig
WorkingDirectory=$XMRIG_DIR/build
User=$USER
Restart=always
Nice=10
CPUAffinity=1-$THREADS

[Install]
WantedBy=multi-user.target
EOL

# --- ENABLE AND START SERVICE ---
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "XMRig installed and running as systemd service '$SERVICE_NAME'."
echo "Check logs with: sudo journalctl -u $SERVICE_NAME -f"

