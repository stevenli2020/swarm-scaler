#On leader node
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
cat .ssh/id_rsa.pub
#On follower node
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHXfY+j3y+oyMlMziJI+gH3/lMx4b/T5KDwOoVfyEQ/yA5+Sl8aE378OvnWVzW1rER7AFYR7monHFpWNCBG1zTTwTFzrjlGuz9Oaj+syChTqHGh+czX8UEvS0DHa8CaOjfHYvBKozlAtYJSOryJT/X9g9J0DaeTZi1l2S9hmOttbyd2KWAJ5YTHBDUV74xpiDaQgNKh/qNaPs92ABqvusJatt9c5SMZK7wbzqUi5sShzjpg3+qMiTVIgPpxTayayeFjCTT42JuBWWGr8SIAsGeO2pJA9uvD4JTjDPvXVKPRKPBfBY0svHvvKPj2n8dwNMRKK53WqYBZ3XQsfva1ITRQCtrPsjYjkt4lJvhp77TtoH58Az08MdgiTRkD72IN3LBAvmdJbVpmQUKhcLT0x7yyWrt4xjgUzh4KccGR6X/pm6TFGYNbsvzEqWUgHXYGsC3e/P8eVOJbEhJyjen5Ok4bMNStsInhTm8FYlsPfctww3YArKJqStiEHYyQLxvwj8= root@sw3" >> .ssh/authorized_keys
ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
#On leader node
curl -sSL https://stevenli.top/swarm-scaler.sh | sh
