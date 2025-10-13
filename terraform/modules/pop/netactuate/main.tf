locals {
  worker_keys = { for idx in range(var.worker_count) : format("w%02d", idx + 1) => idx }

  pkg   = var.plan
  match = can(regex("^VR(\\d+)x(\\d+)x(\\d+)$", local.pkg)) ? regex("^VR(\\d+)x(\\d+)x(\\d+)$", local.pkg) : []

  ram_gb    = length(local.match) == 4 ? tonumber(local.match[1]) : 1
  vcpus     = length(local.match) == 4 ? tonumber(local.match[2]) : 1
  disk_gb   = length(local.match) == 4 ? tonumber(local.match[3]) : 25
  memory_mb = local.ram_gb * 1024
  disk_mb   = local.disk_gb * 1024
}

########################################
# NetActuate server lifecycle
########################################

resource "netactuate_server" "vm" {
  for_each = local.worker_keys

  hostname    = format("%s-%s-%s.worker.demo", var.hostname_prefix, lower(var.pop_code), each.key)
  location_id = var.location_id
  plan        = var.plan
  image_id    = var.image_id
  ssh_key_id  = var.ssh_key_id

  package_billing_contract_id = tostring(var.contract_id)
}

data "netactuate_server" "vm" {
  for_each = netactuate_server.vm

  id = each.value.id
}

data "netactuate_bgp_sessions" "vm" {
  for_each = netactuate_server.vm

  mbpkgid = each.value.id

  # Force the read to occur after Terraform creates or updates the provider-side
  # sessions so the downstream NetBox module receives a populated dataset.
  depends_on = [
    netactuate_bgp_sessions.provider
  ]
}

resource "netactuate_bgp_sessions" "provider" {
  for_each = var.enable_bgp_sessions && var.bgp_group_id != null ? local.worker_keys : {}

  mbpkgid  = tostring(netactuate_server.vm[each.key].id)
  group_id = var.bgp_group_id
  ipv6     = var.bgp_enable_ipv6
}

########################################
# Derived metadata for downstream consumers
########################################

locals {
  server_metadata = {
    for key, srv in netactuate_server.vm :
    key => {
      id          = tostring(srv.id)
      hostname    = data.netactuate_server.vm[key].hostname
      plan        = local.pkg
      plan_id     = tostring(try(data.netactuate_server.vm[key].plan_id, ""))
      image       = try(data.netactuate_server.vm[key].image, "unknown")
      image_id    = tostring(var.image_id)
      contract_id = tostring(var.contract_id)
      location_id = tostring(var.location_id)
      public_ipv4 = trimspace(coalesce(try(data.netactuate_server.vm[key].public_ipv4, data.netactuate_server.vm[key].ip_v4), ""))
      public_ipv6 = trimspace(coalesce(try(data.netactuate_server.vm[key].public_ipv6, data.netactuate_server.vm[key].ip_v6), ""))
      memory_mb   = local.memory_mb
      vcpus       = local.vcpus
      disk_mb     = local.disk_mb
      bgp_sessions = [
        for s in try(data.netactuate_bgp_sessions.vm[key].sessions, []) : {
          provider_peer_ip    = trimspace(try(tostring(s.provider_peer_ip), ""))
          provider_ip_type    = lower(trimspace(try(tostring(s.provider_ip_type), "")))
          customer_peer_ip    = trimspace(try(tostring(s.customer_peer_ip), ""))
          state               = try(tostring(s.state), "")
          config_status       = try(tostring(s.config_status), "")
          last_update         = try(tostring(s.last_update), "")
          description         = trimspace(try(tostring(s.description), ""))
          group_name          = trimspace(try(tostring(s.group_name), ""))
          group_id            = can(tonumber(s.group_id)) ? tonumber(s.group_id) : 0
          provider_asn        = trimspace(try(tostring(s.provider_asn), ""))
          routes              = can(jsondecode(coalesce(try(s.routes_received, null), "[]"))) ? jsondecode(coalesce(try(s.routes_received, null), "[]")) : []
          virtual_server_fqdn = trimspace(try(tostring(s.virtual_server_fqdn), ""))
        }
        if trimspace(try(tostring(s.provider_peer_ip), "")) != ""
      ]
    }
  }
}
