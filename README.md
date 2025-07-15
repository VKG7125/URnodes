# URnodes

## 🛰️ URnetwork Node Deployment + Discord Webhook Monitoring

URnodes is a deployment and monitoring toolkit for running [URnetwork](https://www.urnetwork.io) provider nodes on Ubuntu 22.04 LTS servers. It automates setup, adds **live Discord webhook reporting**, and includes optional **egress traffic enforcement** (with shutdown) for data-capped environments like AWS.

> 📦 Ideal for VPS, cloud, or local VM setups — including support for residential deployments.

---

## ✨ Features

- 🔌 **One-command installation** of URnetwork provider scripts
- 📊 **Egress traffic monitor** using `vnstat`
- 🛑 **Automatic shutdown** when traffic exceeds a configurable monthly limit
- ⚠️ **Warning alerts** via Discord when approaching limit
- 🕒 **Status pings** every 2 hours to show current usage
- ✅ **Startup webhook notification**, including the current URnetwork `client_id`

---

## 🚀 Installation

> 🖥️ Recommended OS: **Ubuntu Server 22.04 LTS**  
> 💬 Make sure you have two [Discord Webhook URLs](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks) ready for:
> - **Status + warning messages**
> - **Shutdown alerts**

Clone this repository and run the setup script:

```bash
git clone https://github.com/YOUR_USERNAME/URnodes.git
cd URnodes
chmod +x bootstrap_node.sh
sudo ./bootstrap_node.sh
```
You will be prompted to:

Set your node ID (for labeling in messages)

Paste in your Discord webhooks

Choose your egress cap settings (optional for home users)

📌 Important Notes
🧠 This script uses vnstat to track TX (egress) bandwidth usage for the current month. You can reset it manually for new VMs or local testing.

🕵️ AWS and other cloud providers may throttle traffic or reduce quality of IPs — local hosting is preferred for maximum bandwidth.

🧵 If you are hosting multiple nodes, each can have its own Discord webhook and unique client ID reporting.

💻 Manual Usage
Check current monthly outbound usage:

bash
Copy
Edit
vnstat -i eth0 -m
Manually trigger a status webhook:

bash
Copy
Edit
sudo /usr/local/bin/egress_notify.sh
🧰 Files Included
File	Purpose
bootstrap_node.sh	Full installation and setup script
/usr/local/bin/shutdown_on_egress.sh	Monitors outbound traffic and shuts down if cap is exceeded
/usr/local/bin/egress_notify.sh	Sends 2-hour interval status messages to Discord
startup_notify.sh	Sends boot notification and URnetwork client ID

💡 To-Do / Ideas
 Weekly reset support (for non-monthly quotas)

 Docker container version

 IP reputation checker

 Auto webhook configurator for multi-node deployments

🤝 Credits
Built with ❤️ for the URnetwork community by [YourName].

Contributions welcome — feel free to fork or open issues!
