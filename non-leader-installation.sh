#On leader node
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
cat .ssh/id_rsa.pub
#On follower node
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDzAze9k3PSYO6Z5h0ClNcYHWAjV3ENba0dKFE15JE1/v8Po3WyB1jZzBr4pJXGJUH0S0QL8+sq2U78zcJIFQU9I67Lr9zbV8XvnZa4ELFj9+6jNrXl8bsZHgCUoQJ80XJubG6Fj3f+3bDoAq9kMMCsvwORSIEDCtWAA8abdBwSEVYkWauuHEu82uyrIxsFz52D76xq/NPAbvwShqq22wuGWLd+wxV3MjrdhrT6zt0fdtXLseM5zorFbvHS8rLBqQof2i5G8jbbPZQ9H2JwwWvYnlhklXz+szJju8mOtsaMzMj94ncMFW3XQQ6pQJjnfgkZAHtK70XufK1QJ+PMBX2gJvmAM8Q2UsdbE63voGUEI+JAwqz3JIpnO156NlFcofPMEew7UagpmWDaj5MDTApaNhHjhMa09qXa+t9bUL4AJ3eQgh2W8A7Qp1RtjIJZQwvq7API77uIhsMY65j84umKbtHHyM+bxOKXBg6HsDts/M/n2pj9hNAkvxteWxNBt10= root@sw3" >> .ssh/authorized_keys