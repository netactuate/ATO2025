# Example Deployment Playbook

# FIND/REPLACE 'ubuntu' with 'ubuntu' to switch over to Ubuntu ( then pick the correct OS for the install in group_vars/all )

This branch is prepped for an anycasted backend site provided from nginx
hosts - everything in [backend]
bgp.yaml - runs on [backend]
group_vars/all - nginx_anycast_ip needs to be set.

# requirements:

pip install git+https://github.com/netactuate/naapi.git@vapi2
ansible-galaxy collection install git+https://github.com/netactuate/ansible-collection-compute.git,vapi2
ansible-galaxy install git+https://github.com/PowerDNS/pdns-ansible.git

# Important Files / Variables:

## keys.pub:

ubuntu user authorized_keys file

## hosts:

ansible playbook inventory file defining infrastructure:
(adding a new node and running createnode.yaml will spawn a new instance)

## group_vars/all:

Contains the account API settings and resource variables that are consistent among all hosts as well as BGP configuration settings for bound IPs in the Anycast space:

# Playbooks:

## main.yaml

Put the series of playbooks in here to run a full install/choose add-on modules.

## createnode.yaml

`ansible-playbook -i hosts createnode.yaml`
Will read in the hosts inventory file and create any new nodes missing from the infrastructure. Idempotent.

## bgp.yaml

`ansible-playbook -i hosts bgp.yaml`
Will read in group_vars/all and host_vars/node for the BGP session and Bird configuration values, and configure BIRD and the node for the bound IPs and configured prefixes in group_vars/all.

## deletenode.yaml

`ansible-playbook -i hosts bgp.yaml`
Destroys and deletes nodes in the hosts file

### tags:

`ansible-playbook -i hosts bgp.yaml --list-tags`

### Limit playbook to a single node:

`ansible-playbook -i hosts bgp.yaml -l nodename`
