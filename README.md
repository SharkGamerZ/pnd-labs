# 🛡️ Practical Network Defense Labs (pnd-labs)

> **Course:** Practical Network Defense (2025-26)  
> **Program:** Master’s Degree in Cybersecurity  
> **University:** Sapienza Università di Roma  
> **Instructor:** Prof. Angelo Spognardi

## 📖 Overview
This repository contains my personal implementations, configurations, and documentation for the **pnd-labs** exercises. 

The original lab environments are designed to run on [Kathará](https://github.com/KatharaFramework/Kathara), a container-based network emulation framework. By leveraging Docker, these labs allow for the deployment and testing of complex network topologies, routing protocols, and security vulnerabilities in a safe, isolated environment.

> [!NOTE]
> This is a personal fork of the official `vitome/pnd-labs` repository. My goal is to maintain a clean, highly readable workbench of solutions to serve as a reference for myself, future assignments, and other students tackling these topologies.

---

## 🚀 Getting Started
To run any of these labs on your local machine, ensure you have Docker and Kathará installed. 

Navigate to a specific lab directory and start the network:
```bash
kathara lstart
```

To tear down the network and clean up the containers once you are finished:
```bash
kathara lclean
```

> [!TIP]
> A note on Topologies: Unless specifically mentioned in an exercise's solution README, all networks utilize the default `lab.conf` provided by the original course materials.

---

## 🔌 Connecting the Host to the Lab
To interact directly with the virtual machines from your physical host (for example, to capture traffic with Wireshark or test web services), you can use the provided `connect-lab.sh` script. 

**What it does:** The script bridges your physical host with the internal Kathará lab network. It creates a virtual Ethernet interface pair (`veth`), attaches one end to the specified virtual LAN's bridge (`br0`), assigns the provided IP address to the un-enslaved end (on your host), and brings both interfaces up.

**How to use it:**
Run the script specifying the desired IP address, subnet mask, and the target LAN name:
```bash
./connect-lab.sh <IP>/<mask> [<lan>]
```
*Example (Connecting to the 'external' network):*
```bash
./connect-lab.sh 192.168.10.2/24 external
```

---

## 💻 Color-Coded Terminal Launcher (`lstart.sh`)
To improve the workflow when dealing with complex topologies, this repository includes an embedded, custom lab launcher script. 

**What it does:**
Instead of manually opening terminals, this script automatically boots the current lab in `--privileged` mode (which is required for many of the advanced routing and firewall exercises) and launches a dedicated, color-coded terminal window for every device in the topology based on its role (e.g., Routers in Slate, PCs in Dark Blue, Attackers in Dark Red). 

> [!WARNING]
> This script strictly requires the `kitty` terminal emulator to function.

**How to use it:**
To use this script seamlessly from within any lab subfolder without messing with relative paths, register it as a local Git alias by running this command once:
```bash
git config --local alias.lstart '!cd "${GIT_PREFIX:-.}" && bash "$(git rev-parse --show-toplevel)/lstart.sh"'
```

Once configured, simply navigate to any lab directory and type:
```bash
git lstart
```

---

## 🗂️ Lab Structure
The repository is divided into thematic modules. **For detailed topologies, step-by-step configurations, and task explanations, please refer to the specific `README.md` inside each lab folder.**

* **Lab 1: Networking 101 and Traffic Monitoring**
  Focuses on foundational IPv4 architecture. Includes manual routing, dynamic address allocation (DHCP), subnetting, and raw traffic dissection using packet sniffers like `tcpdump` and Wireshark.
* **Lab 2: IPv6 Addressing, ICMPv6, and Security**
  Explores the modern IPv6 protocol suite. Covers SLAAC, DHCPv6 Prefix Delegation (PD), MTU discovery, IPv4/IPv6 transition tunnels (ISATAP), and executing Neighbor Discovery Protocol (NDP) threat exercises (cache poisoning, rogue RAs).
* **Lab 4: Network Traffic Regulation and Firewalls**
  Focuses on protecting network perimeters and creating Demilitarized Zones (DMZs). Covers packet filtering, stateful connection tracking, Network Address Translation (NAT masquerading and destination NAT), and transparent firewalls using `iptables` and `ip6tables`.

## 🛠️ Tech Stack & Tools
Throughout these exercises, the following tools and daemons are utilized:
* **Infrastructure:** Kathará, Docker
* **Routing & Addressing:** `iproute2`, `udhcpd`, `radvd` (Router Advertisement Daemon), `dnsmasq`, `dibbler`
* **Traffic Analysis:** Wireshark, `tcpdump`, NetFlow (`nfsen`/`nfdump`)
* **Security & Packet Crafting:** Scapy (Python interactive packet manipulation), THC-IPV6, IPv6 Toolkit 
* **Firewalling:** `iptables`, `ip6tables`
