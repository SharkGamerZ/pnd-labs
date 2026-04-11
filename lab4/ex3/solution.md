# Topology


# Solution
## Setup Host Machine
First of all we have to make the `internal` and `DMZ` accessible from our *host*:
```bash
# Route to internal
ip route add 192.168.100.0/24 via 198.51.100.29  # <- R1's ip

# Route to DMZ
ip route add 203.0.113.0/24 via 198.51.100.29 # <- R1's ip
```
(This is avoidable, we could do the tests from the `ISP` machine, that's already configured)


We're then gonna operate on r1 on the `FORWARD` chain

## Point 1
> [!NOTE]
> Your internal pcs may freely access any Web service, anywhere, on ports 80 and 443, but only if they initiate the connection themselves (i.e. they are allowed to browse the Web). No one outside the internal lan can initiate connections to internal lan, on any port.


On *r1* we do:
```bash
# Forward request, coming from INTERNAL, only to ports 80-443
iptables -A FORWARD -s 192.168.100.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT

# Forward request that are the continuation (ESTABLISHED) to already started connections.
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
```

## Point 2

> [!NOTE] Task 2
> Everyone, including the Internet, can access Web (both ports) and mail in DMZ to access their main functions and for ping. However, no host in DMZ can initiate connections anywhere else.

On *r1* we do:
```bash
# Forward request, coming from everywhere, to DMZ, only to ports 25, 80, 443
iptables -A FORWARD -d 203.0.113.0/24 -p tcp -m multiport --dports 25, 80,443 -j ACCEPT

# (ALREADY PRESENT) Forward request that are the continuation (ESTABLISHED) to already started connections.
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT

# Block every request starting from DMZ (technically redundant)
iptables -A FORWARD -s 203.0.113.0/24 -m state --state NEW -j DROP

# Permit ping requests to the DMZ
iptables -A FORWARD -d 203.0.113.0/24 -p icmp --icmp-type echo-request -j ACCEPT
```


## Point 3

> [!NOTE] Task 3
> Internal users can access the Web servers and mail servers in DMZ via SSH, too. They can also use SSH to reach any host on the Internet. However, hosts in DMZ can only be contacted on port 22 by hosts in the internal lan.
> 

On *r1* we do:
```bash
iptables -A FORWARD -s 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
```

## Ending
```bash
# Reject everything else
iptables -A FORWARD -j REJECT
```


# Final

```bash
# Forward request, coming from INTERNAL, only to ports 80-443
iptables -A FORWARD -s 192.168.100.0/24 -p tcp -m multiport --dports 80,443 -j ACCEPT

# Forward request, coming from everywhere, to DMZ, only to ports 25, 80, 443
iptables -A FORWARD -d 203.0.113.0/24 -p tcp -m multiport --dports 25,80,443 -j ACCEPT


# Block every request starting from DMZ
iptables -A FORWARD -s 203.0.113.0/24 -m state --state NEW -j DROP

# Accept SSH only coming from internal
iptables -A FORWARD -s 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT

# Forward request that are the continuation (ESTABLISHED) to already started connections.
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT

# Reject everything else
iptables -A FORWARD -j REJECT
```


And the table looks like this:
```bash
root@r1:/# iptables -L -n -v --line-numbers
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1        0     0 ACCEPT     6    --  *      *       192.168.100.0/24     0.0.0.0/0            multiport dports 80,443
2        0     0 ACCEPT     6    --  *      *       0.0.0.0/0            203.0.113.0/24       multiport dports 25,80,443
3        0     0 DROP       0    --  *      *       203.0.113.0/24       0.0.0.0/0            state NEW
4        0     0 ACCEPT     6    --  *      *       192.168.100.0/24     0.0.0.0/0            tcp dpt:22
5        0     0 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            state ESTABLISHED
6        0     0 REJECT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            reject-with icmp-port-unreachable

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
root@r1:/# 
```
