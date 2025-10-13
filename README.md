# NetBox Anycast Demo

Use this project to spin up an Anycast lab on NetActuate that is fully documented in NetBox. Terraform/OpenTofu provisions the NetActuate virtual machines and NetBox objects, while the included Ansible plays configure FRR+BGP, publish state back into NetBox, and drop a simple Nginx listener on the anycast address.

## Prerequisites

- OpenTofu/Terraform 1.5 or newer
- Ansible 2.15+ (plus the collections referenced in `anycast/base-ansible-template`)
- NetActuate account with API key access
- NetBox instance reachable from the automation host (your laptop or CI runner)

## Secrets & Environment

Keep credentials out of Git. Export them before running Terraform or Ansible:

```bash
export NETACTUATE_API_KEY="your-netactuate-api-key"
export NETBOX_URL="https://netbox.example.com/api"
export NETBOX_TOKEN="your-netbox-token"
```

The Anycast playbooks read an `auth_token` from `anycast/base-ansible-template/group_vars/all`. Swap the placeholder `API_KEY` for a real token (or load it from Ansible Vault/environment at runtime).

## Configure Inputs

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`, then add the NetBox URL/token, NetActuate SSH key ID, PoPs to deploy, and any other overrides. Leave this file untracked.
2. Adjust `inventory/hosts.ini` if the NetBox host differs from the demo value.

## Provisioning Workflow

1. (Optional) Install NetBox on the target host:
   ```bash
   ansible-playbook -i inventory/hosts.ini install-netbox.yml
   ```
2. Build the Anycast footprint from the repository root:
   ```bash
   ./deploy.sh
   ```
   or execute the steps manually:
   ```bash
   (cd terraform && tofu init && tofu apply)
   (cd anycast/base-ansible-template && ansible-playbook -i hosts bgp.yaml --limit <site>*)
   (cd anycast/base-ansible-template && ansible-playbook -i hosts nginx2.yaml --limit <site>*)
   ```
3. Confirm in NetBox that the new virtual machines, custom fields, BGP sessions, and service records reflect the live FRR state.

## Tear Down

```bash
cd terraform
tofu destroy
```
