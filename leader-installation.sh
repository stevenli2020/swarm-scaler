# System dependancies update
apt update
# Install tools
apt install -y nano curl net-tools python2.7 netcat 
cp /usr/bin/python2.7 /usr/bin/python
# COnfigure private IP addresses of the nodes
export PRIVATE_IP_REMOTE_NODE=10.130.146.136 
export PRIVATE_IP_LOCAL_NODE=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# Create swarm cluster
docker swarm init --advertise-addr $PRIVATE_IP_LOCAL_NODE
# Create manager node join-token
export NODE_JOIN_COMMAND=$(docker swarm join-token manager | grep docker)
# SSH and execute node join as manager
ssh $PRIVATE_IP_REMOTE_NODE "$NODE_JOIN_COMMAND"
# check if nodes are ok
docker node ls # the remote node must be active and reachable
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





