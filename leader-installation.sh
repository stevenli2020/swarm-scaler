# System dependancies update
apt update
# Install tools
apt install -y nano curl net-tools python2.7 netcat 
cp /usr/bin/python2.7 /usr/bin/python
export PRIVATE_IP_REMOTE_NODE=10.130.142.107  # change the IP address of your remote node
export PRIVATE_IP_LOCAL_NODE=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
export NODE_JOIN_COMMAND=$(docker swarm join-token manager | grep docker)
ssh $PRIVATE_IP_REMOTE_NODE "$NODE_JOIN_COMMAND"
docker node ls # the remote node must be active and reachable
git clone https://github.com/stevenli2020/swarm-scaler.git
ADMIN_USER=admin		# input your own admin login id
ADMIN_PASSWORD=admin111 # input your own admin password
cd swarm-scaler
docker stack deploy -c docker-compose.yml mon
docker run --name scaler_api -dit -p8080:80 --restart=always --log-driver json-file --log-opt max-size=10m -v /var/run/docker.sock:/var/run/docker.sock stevenli2019/docker_service_scaler:1.200917
