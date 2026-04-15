# Task

> One router with two lans, both with 2 pcs.  
> The assignment is: to configure the topology to use static IPv6 addresses. 
> 
> You have to provide static GUA addresses to the machines in the topology.
> 
> - lan1 and lan2 must have the subnet 2001:DB8:CAFE:1::/64 and
>   2001:DB8:CAFE:2::/64 respectively
> 
> - pc1, pc2, pc3 and pc4 must have in the Interface ID: 101, 102, 103 and
>   104 respectively.
> 
> - the router r1 has always 1 in the Interface ID of its own address,
>   both link-local and GUA
> 
> Configure:
> - pc1 and pc4 using the `interfaces` file
> - pc2 using the `ip` command
> - pc3 using the `ifconfig` command

# Solution
Let's start understanding the two subnets we have:
- `lan1` = 2001:DB8:CAFE:1::/64
- `lan2` = 2001:DB8:CAFE:2::/64

We can now configure them.

First of all we configure the router `r1`.

📄 **File:** `r1.startup`
```bash
# 1. Set the GUA and Link-Local addresses for LAN1
ip addr add 2001:DB8:CAFE:1::1/64 dev eth0
ip addr add fe80::1/64 dev eth0

# 2. Set the GUA and Link-Local addresses for LAN2
ip addr add 2001:DB8:CAFE:2::1/64 dev eth1
ip addr add fe80::1/64 dev eth1

# 3. Forward IPv6
sysctl -w net.ipv6.conf.all.forwarding=1
```

> [!NOTE]
> In this case we're not setting DNS Servers as usual in the `/etc/resolve.conf`, because it's not required, but if we wanted to, we have to use the CloudFlare and Google IPv6, and not IPv4.

> [!NOTE]
> In this case we're not gonna `flush` the pre-generated addresses, so that the link-local that are auto-generated remain the same without having to regenerate them.

## LAN1

### PC1

> Configure `pc1` using the `interfaces` file

We must first create the file:

📄 **File:** `pc1/etc/network/interfaces.d/eth0`
```bash
auto eth0
iface eth0 inet6 static
  address 2001:DB8:CAFE:1::101/64
  gateway fe80::1
```

So that we can then activate the interface:
📄 **File:** `pc1.startup`
```bash
# 1. Bring up the interface
ifup eth0
```

### PC2
> Configure `pc2` using the `ip` command.

We create the startup file:
📄 **File:** `pc2.startup`
```bash
# 1. Set the IP
ip addr add 2001:db8:cafe:1::102/64 dev eth0

# 2. Set the Gateway
ip route add default via fe80::1 dev eth0
```

## LAN2
### PC3
> Configure `pc3` using the `ifconfig` command

We create the startup file:
📄 **File:** `pc3.startup`
```bash
# 1. Set the IP
ifconfig eth0 inet6 add 2001:db8:cafe:2::103/64

# 2. Set the Gateway
route -A inet6 add default gw fe80::1 dev eth0
```

### PC4
> Configure `pc4` using the `interfaces` file

We must first create the file:

📄 **File:** `pc4/etc/network/interfaces.d/eth0`
```bash
auto eth0
iface eth0 inet6 static
  address 2001:DB8:CAFE:2::104/64
  gateway fe80::1
```

So that we can then activate the interface:
📄 **File:** `pc4.startup`
```bash
# 1. Bring up the interface
ifup eth0
```

# Tests
To make sure our lab is configured correctly, we can do some tests.

First let's start the lab ([take a look at the git alias](../../README.md#color-coded-terminal-launcher-lstartsh)) on our host machine.
```bash
host:~$ git lstart
```
## Inter-LAN Tests
Once it starts, we can try to see if the hosts can reach one another, to ensure connectivity **through the LAN**.  
Let's try from various hosts:
- [x] **PC1 to PC3 (GUA Address):**
  ```console
  root@pc1:/# ping6 -c 1 2001:db8:cafe:2::103
  ```
- [x] **PC4 to Default Gateway (GUA):** 
  ```console
  root@pc4:/# ping6 -c 1 2001:db8:cafe:2::1
  ```
- [x] **PC2 to Default Gateway (Link-Local):** 
  ```console
  root@pc2:/# ping6 -c 1 fe80::1%eth0
  ```
