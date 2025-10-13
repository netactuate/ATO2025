########################################
# NetActuate provisioning for this PoP
########################################

module "netactuate" {
  source = "./netactuate"

  pop_code            = var.pop_code
  hostname_prefix     = var.hostname_prefix
  location_id         = var.location_id
  plan                = var.plan
  image_id            = var.image_id
  contract_id         = var.contract_id
  ssh_key_id          = var.ssh_key_id
  worker_count        = var.worker_count
  bgp_group_id        = var.bgp_group_id
  bgp_enable_ipv6     = var.bgp_enable_ipv6
  enable_bgp_sessions = var.enable_bgp_sessions
}

########################################
# NetBox registration for this PoP
########################################

module "netbox" {
  source = "./netbox"

  pop_code            = var.pop_code
  cluster_type_id     = var.cluster_type_id
  device_role_id      = var.device_role_id
  device_type_id      = var.device_type_id
  vm_tags             = var.vm_tags
  asn                 = var.asn
  bgp_ipv4_prefix     = var.bgp_ipv4_prefix
  local_as_id         = var.local_as_id
  remote_as_id        = var.remote_as_id
  static_bgp_peers    = var.static_bgp_peers
  enable_bgp_sessions = var.enable_bgp_sessions
  bgp_session_status  = var.bgp_session_status
  bgp_enable_ipv6     = var.bgp_enable_ipv6
  servers             = module.netactuate.servers
  netbox_url          = var.netbox_url
  netbox_token        = var.netbox_token

  depends_on = [
    module.netactuate
  ]
}

########################################
# Outputs back to root
########################################

output "netactuate_server_ids" {
  value = module.netactuate.server_ids
}

output "servers" {
  value = module.netactuate.servers
}
