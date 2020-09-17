# autoscaler
autoscaler app for docker swarm

# Deployment
docker run -dit \\<br>--name web.scaler \\<br>
   -p 733:733 \\<br>
   -v ~/autoscaler/docker/conf:/conf \\<br>
   -v /var/run/docker.sock:/var/run/docker.sock \\<br>
   --restart=always \\<br>
   --log-driver json-file \\<br>
   --log-opt max-size=10m \\<br>
   stevenli2019/autoscaler:1.0
