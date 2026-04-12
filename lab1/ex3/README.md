# Task
>Two lan, both with 2 pc and one router.  
>Then, another lan that joins the two routers with a border gateway (r0).  
>The assignment is: to configure the 4 pc and the three routers so that the two lans are reachable and all can reach the Internet.
>- You have to use the 172.16.0.0/16 network and assign subnetworks to all the LANs in the topology. Think about the most suitable approach.
>- r0 has to be the default gateway of the whole network. It is already set up to act as the default gateway. It is connected to the internet via eth0.
>- r1 and r2 have to be the default gateways for "lan1" and "lan2", respectively. They have to have a default route towards r0 and static routes to reach lan1 or lan2. To set up static routes you can use the ip route command (man ip-route).
>- the DNS server can be the server used by the host machine (this has to be set in all the pcs of the lab) or 8.8.8.8
>- the PCs can be configured as you prefer

## Topology

<p align="center">
  <img src="../../img/lab1_ex3_topology.png" width="400">
</p>

# Solution
First of all, let's understand how to split the subnets for the different networks.
We have the **172.16.0.0/16** network.  
As suggested by the professor, we can split this into 3 subnets:
- **Lan1**: 172.16.1.0/24
- **Lan2**: 172.16.2.0/24
- **Internal**: 172.16.254.0/24

Since we are free to configure the PCs as we prefer, we are going to use the `ip` command to statically assign IPs in Lan1, and setup `udhcpd` on `r2`, to dynamically assign IPs in Lan2.

## Lan1
We statically configure Lan1 IPs.  
First we configure `r1`.


📄 **File:** `r1.startup`
```bash
# 0. Flush the pre-existing confs (not required but best practice)
ip addr flush eth0
ip addr flush eth1

# 1. Setup eth1 interface towards Lan1
ip addr add 172.16.1.254/24 dev eth1
ip link set eth1 up

# 2. Setup eth0 interface toward Internal
ip addr add 172.16.254.1/24 dev eth0
ip link set eth0 up

# 3. Add default Gateway
ip route add default via 172.16.254.254

# 4. Add static route to reach Lan2
ip route add 172.16.2.0/24 via 172.16.254.2

# 5. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

Then we statically configure `lan1pc1` and `lan1pc2`, assigning:
- `lan1pc1`: 172.16.1.1
- `lan1pc2`: 172.16.1.2

### Lan1PC1

📄 **File:** `lan1pc1.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Assign the designated IP from the subnet
ip addr add 172.16.1.1/24 dev eth0

# 2. Bring up the interface
ip link set eth0 up

# 3. Add the default gateway (r1)
ip route add default via 172.16.1.254

# 4. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

### Lan1PC2
📄 **File:** `lan1pc2.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Assign the designated IP from the subnet
ip addr add 172.16.1.2/24 dev eth0

# 2. Bring up the interface
ip link set eth0 up

# 3. Add the default gateway (r1)
ip route add default via 172.16.1.254

# 4. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

## Lan2
We setup a dhcp server on `r2` and the clients on `lan2pc1` and `lan2pc2`.  
First we create the conf file for dhcp.

📄 **File:** `r2/etc/udhcpd.conf`
```bash
# The start and end of the IP lease block (the last IP is for r2)
start 172.16.2.1
end   172.16.2.253

# The interface that udhcpd will use
interface eth1

# Options
opt dns 1.1.1.1 8.8.8.8
opt subnet 255.255.255.0
opt router 172.16.2.254
```

Then we make `r2` use it, and configure the rest.

📄 **File:** `r2.startup`
```bash
# 0. Flush the pre-existing confs (not required but best practice)
ip addr flush eth0
ip addr flush eth1

# 1. Setup eth1 interface towards Lan2
ip addr add 172.16.2.254/24 dev eth1
ip link set eth1 up

# 2. Install UDHCPD
dpkg -i /var/cache/apt/archives/*.deb
apt install -f udhcpd

# 3. Make UDHCPD read the conf for Lan2
udhcpd /etc/udhcpd.conf

# 4. Setup eth0 interface toward Internal
ip addr add 172.16.254.2/24 dev eth0
ip link set eth0 up

# 5. Add default Gateway
ip route add default via 172.16.254.254

# 6. Add static route to reach Lan1
ip route add 172.16.1.0/24 via 172.16.254.1

# 7. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

We can finally configure `lan2pc1` and `lan2pc2` to ask the dhcp server for IPs.

### Lan2PC1

📄 **File:** `lan2pc1.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Request the configuration for eth0 from the DHCP server
dhclient eth0

# 2. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

### Lan2PC2
📄 **File:** `lan2pc2.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Request the configuration for eth0 from the DHCP server
dhclient eth0

# 2. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

## Internal
Finally we configure `r0` to interconnect `r1` and `r2`.

📄 **File:** `r0.startup`
```bash
# 1. NAT all traffic directed outside the LAN
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# 2. Set the IP towards Internal LAN
ip addr add 172.16.254.254/24 dev eth0

# 3. Bring up the interface
ip link set eth0 up

# 4. Add static route to reach Lan1
ip route add 172.16.1.0/24 via 172.16.254.1

# 5. Add static route to reach Lan2
ip route add 172.16.2.0/24 via 172.16.254.2

# 6. Configure DNS resolution manually
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

# Tests
To make sure our lab is configured correctly, we can do some tests, as the slides state:
> Configure the 4 pc and the three routers so that the two lans are reachable and
all can reach the Internet

First let's [start the lab](../../README.md#color-coded-terminal-launcher-lstartsh) on our host machine.
```bash
host:~$ git lstart
```

We can then check what IPs were assigned to `lan2pc1` and `lan2pc2`.  
First on `lan2pc1`
```console
root@lan2pc1:/# ip -4 addr show eth0
56: eth0@if55: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 172.16.2.139/24 brd 172.16.2.255 scope global dynamic eth0
       valid_lft 863987sec preferred_lft 863987sec
```

Then on `lan2pc2`
```console
root@lan2pc2:/# ip -4 addr show eth0
58: eth0@if57: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000 link-netnsid 0
    inet 172.16.2.219/24 brd 172.16.2.255 scope global dynamic eth0
       valid_lft 863983sec preferred_lft 863983sec
```

So, the IPs we have are:
- `lan1pc1`: 172.16.1.1/24
- `lan1pc2`: 172.16.1.2/24
- `lan2pc1`: 172.16.2.139/24
- `lan2pc2`: 172.16.2.219/24

## LAN Tests
We can test to see if the hosts can reach one another, to ensure connectivity **through the LANs**.  
Let's try from some hosts:
- [x] **LAN2PC1 to LAN2PC2 (Intra-LAN):**
`root@lan2pc1:/# ping -c 1 172.16.2.219`
- [x] **LAN1PC1 to LAN2PC1 (Inter-LAN):**
`root@lan1pc1:/# ping -c 1 172.16.2.139`
- [x] **LAN2PC2 to R0 (Inter-LAN):**
`root@lan2pc2:/# ping -c 1 172.16.254.254`


## Internet Connectivity
We can then test the **internet connection**:

- [x] **LAN1PC2 Internet Connectivity:**
`root@lan1pc2:/# curl google.it`
- [x] **R2 (LAN2 Gateway) Internet Connectivity:**
`root@r2:/# curl google.it`

# Capturing Packets
As one of the [lab1/ex4](../ex4/) activities, we have to capture the traffic between the hosts of two different LANs, from different positions.  
Specifically from LAN1, LAN2 and Internal.

We can achieve it in two ways:
- Using `tcpdump` on `r1`, `r2` and `r0`.
- Connecting to the different networks with the `connect-lab.sh` and using `wireshark` to sniff the traffic.

We are going to proceed with the latter, for no particular reason.

In particular we are going to generate traffic with a **ping** from `lan1pc1` to `lan2pc1`.


## Sniffing
First let's [start the lab](../../README.md#color-coded-terminal-launcher-lstartsh) on our host machine.
```bash
host:~$ git lstart
```

### LAN1

We first [connect to LAN1](../../README.md#host-to-lab-network-bridge), using an available address.
```bash
host:~$ git connect-lab 172.16.1.3/24 lan1
```

We then open `wireshark`, and start to **listen** on the `veth0` interface.


We **generate the traffic** from `lan1pc1` to `lan2pc1`:
`root@lan1pc1:/# ping -c 1 172.16.2.139`

We collect the data in the [lan1.pcap](./captures/lan1.pcap).

### LAN2

We continue [connecting to LAN2](../../README.md#host-to-lab-network-bridge), using an available address.
```bash
host:~$ git connect-lab 172.16.2.42/24 lan2
```

We then restart to **listen** on `veth0` with `wireshark`.

We **generate the traffic** from `lan1pc1` to `lan2pc1`:
`root@lan1pc1:/# ping -c 1 172.16.2.139`

We collect the data in the [lan2.pcap](./captures/lan2.pcap).

### Internal

Finally we [connecting to Internal](../../README.md#host-to-lab-network-bridge), using an available address.
```bash
host:~$ git connect-lab 172.16.254.42/24 internal
```

We then restart to **listen** on `veth0` with `wireshark`.

We **generate the traffic** from `lan1pc1` to `lan2pc1`:
`root@lan1pc1:/# ping -c 1 172.16.2.139`

We collect the data in the [internal.pcap](./captures/internal.pcap).

# Analyze the data
Analyzing the different captures, from the different LANs, we can see 3 main things:
- IPs remain **unchanged**, from start to finish they remain the same.
- MAC Addresses **change every hop**.
- TTL **changes every hop**, decreasing by 1 at each hop.

If we want to visualize it schematically, let's look at this diagram, about the ICMP Request Packet.  
We have in *blue* **unchanged** fields, and in *orange* **changed** fields from the previous hop.
```mermaid
flowchart LR
    classDef stable  fill:#dbeafe,stroke:#93c5fd,color:#1e3a5f
    classDef changed fill:#fef3c7,stroke:#fbbf24,color:#78350f
    classDef legend  fill:#f8fafc,stroke:#cbd5e1,color:#64748b

    subgraph LAN1["lan1 — capture point"]
        direction TB
        L1a["   ETH src    lan1pc1         \n   ETH dst    r1:eth0          "]:::stable
        L1b["   IP src     172.16.1.1      \n   IP dst     172.16.2.139     "]:::stable
        L1c["   TTL        64              \n   ICMP       type 8 · request  "]:::stable
        L1a ~~~ L1b ~~~ L1c
    end

    subgraph INT["internal — capture point"]
        direction TB
        Ia["   ETH src    r1:eth1          \n   ETH dst    r2:eth1          "]:::changed
        Ib["   IP src     172.16.1.1       \n   IP dst     172.16.2.139     "]:::stable
        Ic["   TTL        63               \n   ICMP       type 8 · request  "]:::changed
        Ia ~~~ Ib ~~~ Ic
    end

    subgraph LAN2["lan2 — capture point"]
        direction TB
        L2a["   ETH src    r2:eth0          \n   ETH dst    lan2pc1          "]:::changed
        L2b["   IP src     172.16.1.1       \n   IP dst     172.16.2.139     "]:::stable
        L2c["   TTL        62               \n   ICMP       type 8 · request  "]:::changed
        L2a ~~~ L2b ~~~ L2c
    end

    LAN1 -->|"r1 · rewrites L2 · TTL −1"| INT
    INT  -->|"r2 · rewrites L2 · TTL −1"| LAN2

```
