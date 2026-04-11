# Task
>A local lan with 2 pcs, a default gateway that also operates as a DHCP server.  
>The assignment is: to manually configure r1 to act as DHCP server and the 2 pcs to request an IP address from it.
>- `r1` is set up with the IP address 192.168.100.30/28. It should use
>  the network 192.168.100.16/28 as the address pool
>- the DNS server can be the server used by the host machine (this has to be set in all the pc of the lab)
>- the default gateway is r1
>
>Then:
>- `pc1` should be configured using the interfaces file
>- `pc2` should be configured using the dhclient command



## Topology
<p align="center">
  <img src="../../img/lab1_ex2_topology.png" width="400">
</p>


# Solution
First of all let's understand the **subnet** that our DHCP server is going to use, 192.168.100.16/28.
```
Network:   192.168.100.16/28     11000000.10101000.01100100.0001 0000 

HostMin:   192.168.100.17        11000000.10101000.01100100.0001 0001
HostMax:   192.168.100.30        11000000.10101000.01100100.0001 1110
```


We must then setup the **DHCP Server** on `r1`, to do so we have to configure the file used by **udhcpd**.

📄 **File:** `r1/etc/udhcpd.conf`
```bash
# The start and end of the IP lease block (the last IP is for r1)
start 192.168.100.17
end   192.168.100.29

# The interface that udhcpd will use
interface eth0

# Options
opt dns 1.1.1.1 8.8.8.8
opt subnet 255.255.255.240
opt router 192.168.100.30
```

And then tell `r1` to use it.

> [!NOTE]
> The `eth1` interface of `r1` is the one connected to the outside.

📄 **File:** `r1.startup`
```bash
# 1. Set the IP of r1
ip addr replace 192.168.100.30/28 dev eth0

# 2. NAT all traffic directed outside the LAN
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# 3. Install UDHCPD
dpkg -i /var/cache/apt/archives/*.deb
apt install -f udhcpd

# 4. Make UDHCPD read the conf
udhcpd /etc/udhcpd.conf

# 5. Configure DNS resolution manually
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
```

## PC1
>`PC1` should be configured using the interfaces file

We must make the interface automatically request the IP from the DHCP server.

📄 **File:** `pc1/etc/network/interfaces.d/eth0`
```text
auto eth0
iface eth0 inet dhcp
```

📄 **File:** `pc1.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Bring up the interface
ifup eth0

# 2. Configure DNS resolution manually
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
```

## PC2
> `PC2` should be configured using the dhclient command

The `dhclient` command automatically configures the interface with dhcp.

📄 **File:** `pc2.startup`
```bash
# 0. Flush the pre-existing conf (not required but best practice)
ip addr flush eth0

# 1. Request the configuration for eth0 to the DHCP server
dhclient eth0

# 2. Configure DNS resolution manually
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
