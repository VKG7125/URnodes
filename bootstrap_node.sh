#!/bin/bash
# bootstrap_node.sh — URnetwork Node Setup with Webhook Monitoring

set -e  # Exit immediately on error

### === USER INPUT ===
echo "🛠  Starting URnetwork Node setup..."
read -p "Enter Node ID (e.g. 1, 2): " NODE_ID
read -p "Enter shutdown Discord webhook URL: " SHUTDOWN_HOOK
read -p "Enter status Discord webhook URL: " NOTIFY_HOOK
read -p "Enter shutdown cap in MiB (e.g. 99328 for 97 GiB): " CAP
read -p "Enter warning cap in MiB (e.g. 94208 for 92 GiB): " WARN

### === INSTALL DEPENDENCIES ===
echo "📦 Installing vnstat, curl, bc..."
sudo apt update && sudo apt install -y vnstat curl bc

### === INSTALL URNETWORK PROVIDER ===
echo "🌐 Installing URnetwork provider..."
if ! command -v urnetwork &> /dev/null; then
    curl -fSsL https://raw.githubusercontent.com/urnetwork/connect/refs/heads/main/scripts/Provider_Install_Linux.sh | bash || true
    echo "⚙️ Waiting for URnetwork binary to become available..."
    sleep 10

    UR_BIN="/root/.local/share/urnetwork-provider/bin/urnetwork"
    if [[ -x "$UR_BIN" ]]; then
        sudo ln -sf "$UR_BIN" /usr/local/bin/urnetwork
        sudo chmod +x /usr/local/bin/urnetwork
        echo "✅ urnetwork binary found and linked."

        # Create systemd service unit
        echo "⚙️ Creating urnetwork.service unit..."
        sudo tee /etc/systemd/system/urnetwork.service > /dev/null <<EOF
[Unit]
Description=URnetwork Provider
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/urnetwork provide
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now urnetwork.service
    else
        echo "❌ urnetwork binary not found at expected path: $UR_BIN" >&2
        exit 1
    fi
else
    echo "✅ URnetwork already installed."
fi

# Prompt for provider auth code
echo "🔑 Authenticating URnetwork provider..."
read -p "Enter your URnetwork Auth Code: " AUTH_CODE
if command -v urnetwork &> /dev/null; then
    urnetwork auth "$AUTH_CODE"
elif [[ -x "/root/.local/share/urnetwork-provider/bin/urnetwork" ]]; then
    /root/.local/share/urnetwork-provider/bin/urnetwork auth "$AUTH_CODE"
else
    echo "❌ urnetwork binary not found—installation may have failed." >&2
    exit 1
fi

### === SCRIPTS SETUP ===
echo "📝 Writing shutdown script..."
sudo tee /usr/local/bin/shutdown_on_egress.sh > /dev/null <<EOF
#!/bin/bash
IFACE=$(ip route | awk '/default/ {print $5}')
CAP=$CAP
WARN=$WARN
LOGFILE="/var/log/egress_shutdown.log"
WEBHOOK_URL="$SHUTDOWN_HOOK"

TX_LINE=\$(vnstat -i \$IFACE -m | awk '/'"\$(date +%Y-%m)"'/')
TX_RAW=\$(echo "\$TX_LINE" | awk '{print \$5}')
UNIT=\$(echo "\$TX_LINE" | awk '{print \$6}')
if [[ "\$UNIT" == "GiB" ]]; then TX=\$(echo "\$TX_RAW * 1024" | bc); else TX=\$TX_RAW; fi

WARN_FILE="/tmp/urnode_warn_sent"
if (( \$(echo "\$TX > \$CAP" | bc -l) )); then
  echo "\$(date): TX \$TX MiB exceeded cap. Shutting down." | tee -a \$LOGFILE
  curl -s -X POST -H "Content-Type: application/json" -d '{"content":"🚨 URnetwork node #$NODE_ID shut down: egress limit reached."}' "\$WEBHOOK_URL"
  shutdown -h now
elif (( \$(echo "\$TX > \$WARN" | bc -l) )); then
  if [[ ! -f "\$WARN_FILE" ]]; then
    echo "\$(date): ⚠️ TX \$TX MiB exceeded warning cap." | tee -a \$LOGFILE
    curl -s -X POST -H "Content-Type: application/json" -d '{"content":"⚠️ URnetwork node #$NODE_ID nearing egress limit."}' "\$WEBHOOK_URL"
    touch "\$WARN_FILE"
  fi
else
  echo "\$(date): TX \$TX MiB — under warning cap." >> \$LOGFILE
  rm -f "\$WARN_FILE"
fi
EOF
sudo chmod +x /usr/local/bin/shutdown_on_egress.sh

### === NOTIFY SCRIPT ===
echo "📡 Writing notify script..."
sudo tee /usr/local/bin/egress_notify.sh > /dev/null <<EOF
#!/bin/bash
IFACE=\$(ip route | awk '/default/ { print \$5; exit }')
WEBHOOK_URL="$NOTIFY_HOOK"
DATE=\$(date '+%Y-%m-%d %H:%M:%S UTC')
TX_LINE=\$(vnstat -i "\$IFACE" -m | awk '/'\$(date +%Y-%m)'/')
TX_RAW=\$(echo "\$TX_LINE" | awk '{print \$5}')
UNIT=\$(echo "\$TX_LINE" | awk '{print \$6}')

curl -s -X POST -H "Content-Type: application/json" \\
     -d "{\\"content\\":\\"📡 URnetwork node #$NODE_ID status update\\\\n• Outbound usage: \$TX_RAW \$UNIT\\\\n• Time: \$DATE\\"}" \\
     "\$WEBHOOK_URL"
EOF
sudo chmod +x /usr/local/bin/egress_notify.sh
sudo /usr/local/bin/egress_notify.sh

### === STARTUP NOTIFICATION ===
echo "🚀 Writing startup notify service..."
sudo tee /usr/local/bin/startup_notify.sh > /dev/null <<EOF
#!/bin/bash
WEBHOOK_URL="$SHUTDOWN_HOOK"
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"content":"✅ URnetwork node #$NODE_ID started up!"}' "\$WEBHOOK_URL"
sleep 10
curl -s -X POST -H "Content-Type: application/json" \
     -d '{"content":"> Client ID:"}' "\$WEBHOOK_URL"
CLIENT_ID=\$(journalctl -u urnetwork.service -n 20 --no-pager | grep -oP 'client_id:\s*\K[\w-]+')
if [[ -n "\$CLIENT_ID" ]]; then
  curl -s -X POST -H "Content-Type: application/json" -d "{\"content\":\"\$CLIENT_ID\"}" "\$WEBHOOK_URL"
else
  curl -s -X POST -H "Content-Type: application/json" -d '{"content":"Client ID not found in logs."}' "\$WEBHOOK_URL"
fi
EOF
sudo chmod +x /usr/local/bin/startup_notify.sh

sudo tee /etc/systemd/system/startup-notify.service > /dev/null <<EOF
[Unit]
Description=Send Discord startup notification with URnetwork client ID
After=urnetwork.service network-online.target

[Service]
ExecStart=/usr/local/bin/startup_notify.sh
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable startup-notify.service

### === CRON JOBS ===
echo "⏱  Setting up cron jobs..."
sudo crontab -u root -l 2>/dev/null | grep -v 'egress_notify\|shutdown_on_egress' > /tmp/current_cron || true
echo "*/5 * * * * /usr/local/bin/shutdown_on_egress.sh >> /var/log/shutdown_cron.log 2>&1" >> /tmp/current_cron
echo "0 */2 * * * /usr/local/bin/egress_notify.sh >> /var/log/notify_cron.log 2>&1" >> /tmp/current_cron
sudo crontab -u root /tmp/current_cron
rm /tmp/current_cron


### === FINALIZE ===
echo "🚀 Starting vnStat and URnetwork provider..."
sudo systemctl start vnstat
sudo systemctl start urnetwork.service
sudo /usr/local/bin/startup_notify.sh

echo "✅ URnetwork Node #$NODE_ID setup complete. Egress monitoring enabled."
