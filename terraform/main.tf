#########################
# NetBox global docs
#########################

# Registry (RIR) required by e-breuninger/netbox for ASNs
resource "netbox_rir" "demo" {
  name        = "Demo RIR"
  slug        = "demo-rir"
  is_private  = false
  description = "RIR for demo ASN objects"
}


resource "netbox_asn" "local" {
  asn         = var.bgp_asn
  rir_id      = netbox_rir.demo.id
  description = "Demo ASN for anycast ingress"
}

resource "netbox_asn" "peer" {
  asn         = var.bgp_peer_asn
  rir_id      = netbox_rir.demo.id
  description = "Remote upstream ASN for anycast peers"
}

resource "netbox_vrf" "anycast" {
  name = "ANYCAST"
  rd   = "${var.bgp_asn}:1"
}

resource "netbox_prefix" "anycast_v4" {
  prefix      = var.bgp_ipv4_prefix
  vrf_id      = netbox_vrf.anycast.id
  status      = "active"
  description = "Anycast IPv4 prefix"
}

# Create the "anycast" tag in NetBox once
resource "netbox_tag" "anycast" {
  name = "anycast"
  slug = "anycast"
}

# Single cluster type used by all POP modules
resource "netbox_cluster_type" "hypervisor" {
  name = "hypervisor"
  slug = "hypervisor"
}

resource "netbox_manufacturer" "netactuate" {
  name = "NetActuate"
  slug = "netactuate"
}

resource "netbox_device_role" "anycast_worker" {
  name      = "Anycast Worker"
  slug      = "anycast-worker"
  color_hex = "ff8a00"
}

resource "netbox_device_type" "anycast_worker" {
  model           = "Anycast Worker VM"
  slug            = "anycast-worker-vm"
  manufacturer_id = netbox_manufacturer.netactuate.id
}



#########################
# Per-PoP module
#########################
module "pop" {
  for_each        = var.pops
  source          = "./modules/pop"
  cluster_type_id = netbox_cluster_type.hypervisor.id
  vm_tags         = [netbox_tag.anycast.name]
  pop_code        = each.key
  location_id     = each.value.location_id
  plan            = each.value.plan
  image_id        = var.image_id
  hostname_prefix = each.value.hostname_prefix
  worker_count    = try(each.value.worker_count, 1)

  contract_id     = var.contract_id
  asn             = var.bgp_asn
  local_as_id     = netbox_asn.local.id
  remote_as_id    = netbox_asn.peer.id
  bgp_ipv4_prefix = var.bgp_ipv4_prefix

  bgp_group_id    = var.bgp_group_id
  bgp_enable_ipv6 = var.bgp_enable_ipv6

  device_role_id = netbox_device_role.anycast_worker.id
  device_type_id = netbox_device_type.anycast_worker.id

  static_bgp_peers = lookup(var.static_bgp_peers, each.key, { ipv4 = [], ipv6 = [] })

  # NEW: key id for server creation
  ssh_key_id = var.ssh_key_id

  netbox_url   = var.netbox_url
  netbox_token = var.netbox_token

  depends_on = [
    netbox_custom_field.na_server_id,
    netbox_custom_field.na_contract_id,
    netbox_custom_field.na_asn,
    netbox_custom_field.na_bgp_ipv4_prefix,
    netbox_custom_field.na_plan,
    netbox_custom_field.na_plan_id,
    netbox_custom_field.na_image_id,
    netbox_custom_field.na_image,
    netbox_custom_field.na_location_id,
    netbox_custom_field.na_public_ipv4,
    netbox_custom_field.na_public_ipv6,
    netbox_custom_field.na_bgp_peers,
    netbox_custom_field.na_bgp_session_details,
    # BGP breakdown fields for VM page visibility
    netbox_custom_field.zz_bgp_local_info,
    netbox_custom_field.zz_bgp_remote_info,
    netbox_custom_field.zz_bgp_connection_info,
    netbox_custom_field.zz_bgp_routes_info,
  ]
}

#########################
# Outputs like your sample
#########################

locals {
  pop_servers = { for pop, mod in module.pop : pop => mod.servers }

  flat_servers = flatten([
    for pop, servers in local.pop_servers : [
      for worker_key, server in servers : {
        pop_code   = pop
        worker_key = worker_key
        server     = server
      }
    ]
  ])

  ansible_hosts = {
    for entry in local.flat_servers :
    entry.server.hostname => {
      ansible_host = entry.server.public_ipv4 != "" ? entry.server.public_ipv4 : entry.server.public_ipv6
      hostname     = entry.server.hostname
      pop_code     = entry.pop_code
      worker_key   = entry.worker_key
    }
    if entry.server.public_ipv4 != "" || entry.server.public_ipv6 != ""
  }
}

output "server_data" {
  value = local.pop_servers
}

output "bgp_sessions_data" {
  value = {
    for pop, servers in local.pop_servers :
    pop => {
      for worker_key, server in servers :
      worker_key => server.bgp_sessions
    }
  }
}

output "ansible_inventory_json" {
  value = {
    all = {
      hosts = local.ansible_hosts
    }
  }
}
