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

### 1. Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/URnodes.git
cd URnodes
```
### 2. Run the bootstrap script

```bash
chmod +x bootstrap_node.sh
sudo ./bootstrap_node.sh
```

You will be prompted to:
> - Enter a node number (e.g., 1, 2, etc.)
> - Paste your Discord webhook URLs
> - Confirm your TX limit and warning threshold (in MiB)
