#!/bin/bash
# System dependancies update
yum check-update

# Install tools
yum install -y nano curl net-tools python2.7 nc git

# COnfigure private IP addresses of the nodes
PRIVATE_IP_REMOTE_NODE=xx.xx.xx.xx
PRIVATE_IP_LOCAL_NODE=yy.yy.yy.yy

# Start docker daemon
systemctl start docker
systemctl enable docker
ssh PRIVATE_IP_REMOTE_NODE systemctl start docker && systemctl enable docker

# Create swarm cluster
docker swarm init --advertise-addr $PRIVATE_IP_LOCAL_NODE

# Create manager node join-token
NODE_JOIN_COMMAND=$(docker swarm join-token manager | grep docker)

# SSH and execute node join as manager
ssh $PRIVATE_IP_REMOTE_NODE "$NODE_JOIN_COMMAND" 
docker node ls 

# the remote node must be active and reachable
# Create application service
docker service create --name web --replicas=2 -p80:80  nginx

# Installing Swarmprom stack
git clone https://github.com/stevenli2020/swarm-scaler.git

ADMIN_USER=admin		# input your own admin login id

ADMIN_PASSWORD=admin111 # input your own admin password

cd swarm-scaler

docker stack deploy -c docker-compose.yml mon

# Installing scaler api service container
docker run --name scaler_api -dit -p8080:80 --restart=always --memory="128m" --log-driver json-file --log-opt max-size=10m -v /var/run/docker.sock:/var/run/docker.sock stevenli2019/docker_service_scaler:1.200917

# Installing autoscaler as systemd service
cp autoscaler/autoscaler.service /etc/systemd/system/.

mkdir /etc/autoscaler

cp autoscaler/config /etc/autoscaler/.

cp autoscaler/autoscaler.py /sbin/.

# Install autoscaler systemd service on leader manager
systemctl start autoscaler
systemctl enable autoscaler

# Install autoscaler systemd service on remote manager node
scp -r autoscaler $PRIVATE_IP_REMOTE_NODE:/root/.
printf "yum check-update\nyum install -y nano curl net-tools python2.7 nc\ncp ~/autoscaler/autoscaler.service /etc/systemd/system/.\nmkdir /etc/autoscaler\ncp ~/autoscaler/config /etc/autoscaler/.\nsed -i -- 's/\"LEADER\"/\"FOLLOWER\"/g' /etc/autoscaler/config\nsed -i -- 's/\"0.0.0.0\"/\"$PRIVATE_IP_LOCAL_NODE\"/g' /etc/autoscaler/config\ncp ~/autoscaler/autoscaler.py /sbin/.\nsystemctl start autoscaler\nsystemctl enable autoscaler\n" > setup.sh
scp setup.sh $PRIVATE_IP_REMOTE_NODE:/root/.
ssh $PRIVATE_IP_REMOTE_NODE sh setup.sh

