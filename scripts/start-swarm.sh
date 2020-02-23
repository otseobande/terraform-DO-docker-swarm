#!/bin/bash
private_ip=$(hostname -I | cut -d " " -f 3)

docker swarm init \
--listen-addr $private_ip \
--advertise-addr $private_ip
