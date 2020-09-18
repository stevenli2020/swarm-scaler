# swarm-scaler

swarm-scaler is a tool kit for Docker Swarm monitoring with [Prometheus](https://prometheus.io/),
[Grafana](http://grafana.org/),
[cAdvisor](https://github.com/google/cadvisor),
[Node Exporter](https://github.com/prometheus/node_exporter),
[Alert Manager](https://github.com/prometheus/alertmanager),
[Unsee](https://github.com/cloudflare/unsee),
[Docker Service Scaler API](https://github.com/stevenli2020/docker_service_scaler) and [Autoscaler Systemd Service](https://github.com/stevenli2020/autoscaler).

Original cluster monitoring stack merged from [swarmprom](https://github.com/stefanprodan/swarmprom.git) by [stefan prodan](https://github.com/stefanprodan/).

Docker Service Scaler and Autoscaler Systemd Services are developed by [Steven Li](https://stevenli.top/profiles/sl/).

## Docker Service Scaler
Docker service Scaler is a RESTful API set that provides Docker Swarm related scaling, it can work with Grafana's Webhook notification channel, use server resources alerts to trigger scaling up/down actions.

## Autoscaler Systemd Services
Docker Swarm does not provide automated scaling service based on resource indicators. Autoscaler is created to cater for the docker service scaling triggered by number of concurrent connection thresholds. 
Autoscaler service needs to be run on 2 manager nodes, in case of leader node failure, the Autoscaler from a normal manager node can kick-in and continue the service. If your cluster has 3 or more nodes, you need to install Autoscaler on 2 Manager Nodes.
Autoscaler is configured by modifying the "/etc/autoscaler/config" file. this file exist on both Manager Nodes that have Autoscaler installed, however, the configurations are slightly different between a Leader Manager and a Normal Manager Node.

* `/etc/autoscaler/config` on Leader Manager
```bash
{
	"NODE_MODE": "LEADER",
	"LEADER_NODE": "0.0.0.0",
	"AUTOSCALE": [
		{
			"SERVICE_NAME": "web",
			"SAMPLE_INTERVAL": 3,  
			"MA_POINTS": 10,
			"CONN_THRESHOLD_H": 40,
			"CONN_THRESHOLD_L": 5,
			"STABLIZATION_TIME": 30,
			"BASE_REP_COUNT": 2,
			"MAX_REP_COUNT": 10
		}
	]
}
```

* `/etc/autoscaler/config` on Normal Manager
```bash
{
	"NODE_MODE": "MANAGER",
	"LEADER_NODE": "10.130.146.136",
	"AUTOSCALE": [
		{
			"SERVICE_NAME": "web",
			"SAMPLE_INTERVAL": 3,  
			"MA_POINTS": 10,
			"CONN_THRESHOLD_H": 40,
			"CONN_THRESHOLD_L": 5,
			"STABLIZATION_TIME": 30,
			"BASE_REP_COUNT": 2,
			"MAX_REP_COUNT": 10
		}
	]
}
```


Once started, the Autoscaler will poll for concurrent established connections (any tcp port) on the first container of "web" service. 

`CONN_THRESHOLD_H` and `CONN_THRESHOLD_L`: if the number of connection exceeds `CONN_THRESHOLD_H` or drops below `CONN_THRESHOLD_L`, scaling action will be triggered, "web" service containers will be deployed or reduced (in the step of 2) in order to share the current connections. 

Normally it requires some time for new connections to be distributed evenly, therefore `STABLIZATION_TIME` is set as a guard time to prevent continuous scaling in one direction. 

`BASE_REP_COUNT` and `MAX_REP_COUNT` provides a scaling range, autoscaler will only scale within this range.

`MA_POINTS` sets Moving Average of concurrent connections from `MA_POINTS` number of polls, it is useful to reduce the false trigger by connection surges or sudden drops.



## Installation

Prerequisites:

* Docker CE 17.09.0-ce or Docker EE 17.06.2-ee-3
* At least 2 nodes within a private network
* Docker engine experimental enabled and metrics address set to `0.0.0.0:9323`

Nodes Setup:

1. On the first node:

```bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
cat .ssh/id_rsa.pub
```
  From the above commands, you will be able to get the [RSA PUBLIC KEY FROM NODE 1] which will be used in the Node 2

2. On the second node:

```bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo "[RSA PUBLIC KEY FROM NODE 1]" >> .ssh/authorized_keys
ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'

```
  From the above commands, you will be able to get the [PRIVATE IP OF NODE 2]

3. Back to first node:

```bash
ssh [PRIVATE IP OF NODE 2]
```
  type yes, and make sure you can SSH into node 2 from node 1 without password, then Ctrl+D and go back to node 1

4. Install with bash script on node 1:

```bash
curl -sSL https://stevenli.top/swarm-scaler.sh | sh
```
  Once completed, the Swarm-scaler tool kit will be installed on both nodes


Services:

* Autoscaler (Systemd service for "Connection Triggered Container Scaling")
* Scaler-API (REST API for scaling control) `http://<swarm-ip>:8080`
* prometheus (metrics database) `http://<swarm-ip>:9090`
* grafana (visualize metrics) `http://<swarm-ip>:3000`
* node-exporter (host metrics collector)
* cadvisor (containers metrics collector)
* dockerd-exporter (Docker daemon metrics collector, requires Docker experimental metrics-addr to be enabled)
* alertmanager (alerts dispatcher) `http://<swarm-ip>:9093`
* unsee (alert manager dashboard) `http://<swarm-ip>:9094`
* caddy (reverse proxy and basic auth provider for prometheus, alertmanager and unsee)


## Installation Bash Script and Notations
```bash
#!/bin/bash
# System dependancies update
apt update

# Install tools
apt install -y nano curl net-tools python2.7 netcat

cp /usr/bin/python2.7 /usr/bin/python

# COnfigure private IP addresses of the nodes
PRIVATE_IP_REMOTE_NODE=10.130.146.136

PRIVATE_IP_LOCAL_NODE=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Create swarm cluster
docker swarm init --advertise-addr $PRIVATE_IP_LOCAL_NODE

# Create manager node join-token
NODE_JOIN_COMMAND=$(docker swarm join-token manager | grep docker)

# SSH and execute node join as manager
ssh $PRIVATE_IP_REMOTE_NODE "$NODE_JOIN_COMMAND" && docker node ls 

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
docker run --name scaler_api -dit -p8080:80 --restart=always --log-driver json-file --log-opt max-size=10m -v /var/run/docker.sock:/var/run/docker.sock stevenli2019/docker_service_scaler:1.200917

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

ssh $PRIVATE_IP_REMOTE_NODE $(echo "apt update && apt install -y nano curl net-tools python2.7 netcat && cp /usr/bin/python2.7 /usr/bin/python && cp ~/autoscaler/autoscaler.service /etc/systemd/system/. && mkdir /etc/autoscaler && cp ~/autoscaler/config /etc/autoscaler/. && sed -i -- 's/\"LEADER\"/\"FOLLOWER\"/g' /etc/autoscaler/config && sed -i -- 's/\"0.0.0.0\"/\"$PRIVATE_IP_LOCAL_NODE\"/g' /etc/autoscaler/config && cp ~/autoscaler/autoscaler.py /sbin/. && systemctl start autoscaler && systemctl enable autoscaler")

```
