# URnodes

![Social Preview](https://raw.githubusercontent.com/VKG7125/URnodes/refs/heads/main/urnodebanner.jpeg)

## 🛰️ URnetwork Node Deployment + Discord Webhook Monitoring

URnodes is a deployment and monitoring toolkit for running [URnetwork](https://www.ur.io) provider nodes on Ubuntu 22.04 LTS servers. It automates setup, adds **live Discord webhook reporting**, and includes optional **egress traffic enforcement** (with shutdown) for data-capped environments like AWS.

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
git clone https://github.com/VKG7125/URnodes.git
cd URnodes
```
### 2. Run the bootstrap script

```bash
chmod +x bootstrap_node.sh
sudo ./bootstrap_node.sh
```

You will be prompted to:
- Enter a node number (e.g., 1, 2, etc.)
- Paste your Discord webhook URLs
- Confirm your TX limit and warning threshold (in MiB)
- Provide URnetwork auth code (*from the website*)

---

## 🧪 Manual Commands

### Determine your network interface and check outbound (TX) usage for the month:
```bash
# Auto-detect your primary interface (e.g., eth0, ens3, ens1)
IFACE=$(ip route | awk '/default/ {print $5; exit}')

# Display monthly stats for that interface
vnstat -i "$IFACE" -m
```

> Note: vnstat records in *MiB* **not** *MB*
### Manually trigger the Discord status message:
```bash
sudo /usr/local/bin/egress_notify.sh
```

---

## 📁 Files Overview

| File                                   | Description                                 |
| -------------------------------------- | ------------------------------------------- |
| `bootstrap_node.sh`                    | Main setup script | installs everything     |
| `/usr/local/bin/shutdown_on_egress.sh` | Monitors usage, shuts down on cap breach, and notifies of impending breaching (e.g., 5 GB away from set cap) / shutdown to Discord |
| `/usr/local/bin/egress_notify.sh`      | Sends status updates to Discord             |
| `/usr/local/bin/startup_notify.sh`     | Sends boot and client ID notifications      |

---

## 📌 Notes

- 🧠 Monthly data is tracked by vnstat using TX (egress) traffic on your default network interface (auto‑detected via the scripts)
- ⏱️ Cron jobs handle all regular checks:
  -   Every 5 min for shutdown checks
  -   Every 2 hours for status pings
- 🧵 Each node can have its own webhook and unique labeling
- 🔁 Optional: can be configured to reset traffic weekly
- ➕ Considering adding the ability to opt out of any of the three scripts during setup. 
- 📶 If my machine has unlimited egress bandwidth, I just type an egregiously large number that will theoretically never be reached for the **shutdown and warning caps**

---

## 🏠 Hosting Locally?

No problem! The scripts can also run on local VirtualBox or Docker VMs. Multipass was used in testing and developing this script.
If you're not data capped, just ignore the shutdown feature. (*Last Note*)
It’s still useful for logging and monitoring! 

---

## 🤝 Credits

Created by **VKG7125** for the URnetwork community.
Pull requests, suggestions, and issues are welcome!

You can also [DM me on Discord](https://discordapp.com/users/849096985880559616)!
