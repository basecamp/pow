#!/bin/sh -e
sudo ipfw add fwd 127.0.0.1,20559 tcp from any to any dst-port 80 in
sudo sysctl -w net.inet.ip.forwarding=1
