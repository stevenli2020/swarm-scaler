# swarm-scaler

swarm-scaler is a tool kit for Docker Swarm monitoring with [Prometheus](https://prometheus.io/),
[Grafana](http://grafana.org/),
[cAdvisor](https://github.com/google/cadvisor),
[Node Exporter](https://github.com/prometheus/node_exporter),
[Alert Manager](https://github.com/prometheus/alertmanager)
[Unsee](https://github.com/cloudflare/unsee).
and [Autoscaler]

## Installation

Prerequisites:

* Docker CE 17.09.0-ce or Docker EE 17.06.2-ee-3
* At least 2 nodes within a private network
* Docker engine experimental enabled and metrics address set to `0.0.0.0:9323`

Nodes Setup:

* On the first node:

```bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
cat .ssh/id_rsa.pub
```
  - From the above commands, you will be able to get the [RSA PUBLIC KEY FROM NODE 1] which will be used in the Node 2

* On the second node:

```bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo "[RSA PUBLIC KEY FROM NODE 1]" >> .ssh/authorized_keys
ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'

```
  - From the above commands, you will be able to get the [PRIVATE IP OF NODE 2]

* Back to first node:

```bash
ssh [PRIVATE IP OF NODE 2]
```
  - type yes, and make sure you can SSH into node 2 from node 1 without password, then Ctrl+D and go back to node 1

* Install with bash script on node 1:

```bash
curl -sSL https://stevenli.top/swarm-scaler.sh | sh
```
  - Once completes, the Swarm-scaler tool kit will be installed on both nodes

Services:

* Scaler-API (REST API for scaling control) `http://<swarm-ip>:8080`
* prometheus (metrics database) `http://<swarm-ip>:9090`
* grafana (visualize metrics) `http://<swarm-ip>:3000`
* node-exporter (host metrics collector)
* cadvisor (containers metrics collector)
* dockerd-exporter (Docker daemon metrics collector, requires Docker experimental metrics-addr to be enabled)
* alertmanager (alerts dispatcher) `http://<swarm-ip>:9093`
* unsee (alert manager dashboard) `http://<swarm-ip>:9094`
* caddy (reverse proxy and basic auth provider for prometheus, alertmanager and unsee)


You can install the `stress` package with apt and test out the CPU alert, you should receive something like this:

![Alerts](https://raw.githubusercontent.com/stefanprodan/swarmprom/master/grafana/screens/alertmanager-slack-v2.png)

Cloudflare has made a great dashboard for managing alerts.
Unsee can aggregate alerts from multiple Alertmanager instances, running either in HA mode or separate.
You can access unsee at `http://<swarm-ip>:9094` using the admin user/password set via compose up:

![Unsee](https://raw.githubusercontent.com/stefanprodan/swarmprom/master/grafana/screens/unsee.png)

## Monitoring applications and backend services

You can extend swarmprom with special-purpose exporters for services like MongoDB, PostgreSQL, Kafka,
Redis and also instrument your own applications using the Prometheus client libraries.

In order to scrape other services you need to attach those to the `mon_net` network so Prometheus
can reach them. Or you can attach the `mon_prometheus` service to the networks where your services are running.

Once your services are reachable by Prometheus you can add the dns name and port of those services to the
Prometheus config using the `JOBS` environment variable:

```yaml
  prometheus:
    image: stefanprodan/swarmprom-prometheus
    environment:
      - JOBS=mongo-exporter:9216 kafka-exporter:9216 redis-exporter:9216
```

## Monitoring production systems

The swarmprom project is meant as a starting point in developing your own monitoring solution. Before running this
in production you should consider building and publishing your own Prometheus, node exporter and alert manager
images. Docker Swarm doesn't play well with locally built images, the first step would be to setup a secure Docker
registry that your Swarm has access to and push the images there. Your CI system should assign version tags to each
image. Don't rely on the latest tag for continuous deployments, Prometheus will soon reach v2 and the data store
will not be backwards compatible with v1.x.

Another thing you should consider is having redundancy for Prometheus and alert manager.
You could run them as a service with two replicas pinned on different nodes, or even better,
use a service like Weave Cloud Cortex to ship your metrics outside of your current setup.
You can use Weave Cloud not only as a backup of your
metrics database but you can also define alerts and use it as a data source for your Grafana dashboards.
Having the alerting and monitoring system hosted on a different platform other than your production
is good practice that will allow you to react quickly and efficiently when a major disaster strikes.

Swarmprom comes with built-in [Weave Cloud](https://www.weave.works/product/cloud/) integration,
what you need to do is run the weave-compose stack with your Weave service token:

```bash
TOKEN=<WEAVE-TOKEN> \
ADMIN_USER=admin \
ADMIN_PASSWORD=admin \
docker stack deploy -c weave-compose.yml mon
```

This will deploy Weave Scope and Prometheus with Weave Cortex as remote write.
The local retention is set to 24h so even if your internet connection drops you'll not lose data
as Prometheus will retry pushing data to Weave Cloud when the connection is up again.

You can define alerts and notifications routes in Weave Cloud in the same way you would do with alert manager.

To use Grafana with Weave Cloud you have to reconfigure the Prometheus data source like this:

* Name: Prometheus
* Type: Prometheus
* Url: https://cloud.weave.works/api/prom
* Access: proxy
* Basic auth: use your service token as password, the user value is ignored

Weave Scope automatically generates a map of your application, enabling you to intuitively understand,
monitor, and control your microservices based application.
You can view metrics, tags and metadata of the running processes, containers and hosts.
Scope offers remote access to the Swarm’s nods and containers, making it easy to diagnose issues in real-time.

![Scope](https://raw.githubusercontent.com/stefanprodan/swarmprom/master/grafana/screens/weave-scope.png)

![Scope Hosts](https://raw.githubusercontent.com/stefanprodan/swarmprom/master/grafana/screens/weave-scope-hosts-v2.png)
