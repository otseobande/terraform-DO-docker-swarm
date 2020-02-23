#!/bin/bash
public_ip=$(hostname -I | cut -d " " -f 3)
#$(dig +short myip.opendns.com @resolver1.opendns.com)

docker swarm init \
--listen-addr $public_ip \
--advertise-addr $public_ip
