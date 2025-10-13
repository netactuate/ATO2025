########################################
# Derived session and metadata context
########################################

locals {
  valid_bgp_statuses          = ["active", "failed", "offline", "planned"]
  normalized_bgp_status_input = lower(var.bgp_session_status)
  default_bgp_status          = contains(local.valid_bgp_statuses, local.normalized_bgp_status_input) ? local.normalized_bgp_status_input : "active"

  session_state_to_status = {
    "established" = "active"
    "up"          = "active"
    "running"     = "active"
    "ok"          = "active"
    "connect"     = "planned"
    "connecting"  = "planned"
    "idle"        = "offline"
    "down"        = "failed"
    "failed"      = "failed"
    "active"      = "failed"
  }

  server_context = {
    for key, server in var.servers :
    key => ({
      server          = server
      pub_v4_clean    = trimspace(coalesce(server.public_ipv4, ""))
      pub_v6_clean    = trimspace(coalesce(server.public_ipv6, ""))
      has_pub_v4      = trimspace(coalesce(server.public_ipv4, "")) != ""
      has_pub_v6      = trimspace(coalesce(server.public_ipv6, "")) != ""
      session_details = try(server.bgp_sessions, [])
    })
  }

  server_context_extended = {
    for key, ctx in local.server_context :
    key => merge(ctx, {
      session_details_extended = [
        for s in ctx.session_details : {
          remote_ip = trimspace(s.provider_peer_ip)
          remote_ip_type = (
            lower(trimspace(s.provider_ip_type)) == "ipv6" ||
            strcontains(trimspace(s.provider_peer_ip), ":")
          ) ? "ipv6" : "ipv4"
          state            = trimspace(try(s.state, ""))
          config_status    = trimspace(try(s.config_status, ""))
          last_update      = trimspace(try(s.last_update, ""))
          description      = trimspace(try(s.description, ""))
          routes           = try(s.routes, [])
          customer_peer_ip = trimspace(try(s.customer_peer_ip, ""))
          group_id         = s.group_id
          group_name       = trimspace(try(s.group_name, ""))
          session_name     = trimspace(try(s.virtual_server_fqdn, ""))
          provider_asn     = trimspace(try(s.provider_asn, ""))
        }
        if trimspace(s.provider_peer_ip) != ""
      ]
    })
  }

  server_context_sessions = {
    for key, ctx in local.server_context_extended :
    key => merge(ctx, {
      static_session_inputs = merge(
        {
          for ip in try(var.static_bgp_peers.ipv4, []) :
          format("ipv4|%s", lower(trimspace(ip))) => {
            remote_ip        = trimspace(ip)
            remote_ip_type   = "ipv4"
            customer_peer_ip = ctx.pub_v4_clean
            state            = ""
            config_status    = ""
            last_update      = ""
            description      = ""
            routes           = []
            group_id         = 0
            group_name       = ""
            session_name     = ""
            provider_asn     = ""
            status           = local.default_bgp_status
          }
          if trimspace(ip) != "" && ctx.has_pub_v4
        },
        {
          for ip in try(var.static_bgp_peers.ipv6, []) :
          format("ipv6|%s", lower(trimspace(ip))) => {
            remote_ip        = trimspace(ip)
            remote_ip_type   = "ipv6"
            customer_peer_ip = ctx.pub_v6_clean
            state            = ""
            config_status    = ""
            last_update      = ""
            description      = ""
            routes           = []
            group_id         = 0
            group_name       = ""
            session_name     = ""
            provider_asn     = ""
            status           = local.default_bgp_status
          }
          if trimspace(ip) != "" && ctx.has_pub_v6
        }
      )

      dynamic_session_inputs = {
        for s in ctx.session_details_extended :
        format("%s|%s", s.remote_ip_type, lower(s.remote_ip)) => merge(s, {
          status = lookup(local.session_state_to_status, lower(s.state), local.default_bgp_status)
        })
        if s.remote_ip != "" && (
          (s.remote_ip_type == "ipv4" && ctx.has_pub_v4) ||
          (s.remote_ip_type == "ipv6" && ctx.has_pub_v6)
        )
      }
    })
  }

  server_context_peers = {
    for key, ctx in local.server_context_sessions :
    key => merge(ctx, {
      all_session_inputs = merge(ctx.static_session_inputs, ctx.dynamic_session_inputs)
    })
  }

  server_context_full = {
    for key, ctx in local.server_context_peers :
    key => merge(ctx, {
      remote_peer_map = {
        for map_key, s in ctx.all_session_inputs :
        map_key => merge(s, {
          remote_prefix = s.remote_ip_type == "ipv6" ? format("%s/128", s.remote_ip) : format("%s/32", s.remote_ip)
          description   = s.description != "" ? s.description : format("NetActuate peer for %s", ctx.server.hostname)
          comment = trimspace(join("\n", compact([
            s.description != "" ? format("Description: %s", s.description) : null,
            s.state != "" ? format("State: %s", s.state) : null,
            s.config_status != "" ? format("Config status: %s", s.config_status) : null,
            s.last_update != "" ? format("Last update: %s", s.last_update) : null,
            length(s.routes) > 0 ? format(
              "Routes: %s",
              join(", ", [for r in s.routes : format(
                "%s via %s",
                coalesce(try(r.prefix, try(r["prefix"], null)), "unknown"),
                coalesce(try(r.next_hop, try(r["next_hop"], null)), s.customer_peer_ip != "" ? s.customer_peer_ip : "unknown")
              )])
            ) : null
          ])))
        })
        if s.remote_ip != ""
      }
    })
  }

  server_context_metadata = {
    for key, ctx in local.server_context_full :
    key => merge(ctx, {
      metadata_group_name = length(ctx.session_details_extended) > 0 ? ctx.session_details_extended[0].group_name : ""
      metadata_group_id   = length(ctx.session_details_extended) > 0 ? ctx.session_details_extended[0].group_id : null
      provider_asn_value  = length(ctx.session_details_extended) > 0 ? ctx.session_details_extended[0].provider_asn : ""
      local_peer_ips = distinct(compact([
        for s in ctx.session_details_extended : s.customer_peer_ip
        if s.customer_peer_ip != ""
      ]))
      remote_peer_v4 = distinct(compact([
        for s in ctx.session_details_extended : s.remote_ip
        if s.remote_ip_type == "ipv4"
      ]))
      remote_peer_v6 = distinct(compact([
        for s in ctx.session_details_extended : s.remote_ip
        if s.remote_ip_type == "ipv6"
      ]))
    })
  }

  server_context_text = {
    for key, ctx in local.server_context_metadata :
    key => merge(ctx, {
      local_info_lines = compact([
        format("Hostname: %s", ctx.server.hostname),
        format("Local ASN: %s", tostring(var.asn)),
        ctx.has_pub_v4 ? format("Public IPv4: %s", ctx.pub_v4_clean) : null,
        ctx.has_pub_v6 ? format("Public IPv6: %s", ctx.pub_v6_clean) : null,
        length(ctx.local_peer_ips) > 0 ? format("Customer IPs: %s", join(", ", ctx.local_peer_ips)) : null
      ])
      remote_info_lines = compact([
        ctx.metadata_group_name != "" ? format("Group: %s", ctx.metadata_group_name) : null,
        ctx.provider_asn_value != "" ? format("Provider ASN: %s", ctx.provider_asn_value) : null,
        length(ctx.remote_peer_v4) > 0 ? format("Provider IPv4: %s", join(", ", ctx.remote_peer_v4)) : null,
        length(ctx.remote_peer_v6) > 0 ? format("Provider IPv6: %s", join(", ", ctx.remote_peer_v6)) : null
      ])
      connection_info_lines = [
        for s in ctx.session_details_extended : format(
          "%s (%s): state=%s config=%s last=%s",
          s.remote_ip,
          s.remote_ip_type,
          s.state != "" ? s.state : "unknown",
          s.config_status != "" ? s.config_status : "unknown",
          s.last_update != "" ? s.last_update : "n/a"
        )
      ]
      routes_info_lines = flatten([
        for s in ctx.session_details_extended : [
          for r in s.routes : format(
            "%s via %s (origin %s)",
            coalesce(try(r.prefix, try(r["prefix"], null)), "unknown"),
            coalesce(try(r.next_hop, try(r["next_hop"], null)), s.customer_peer_ip != "" ? s.customer_peer_ip : "unknown"),
            coalesce(try(r.origin, try(r["origin"], null)), "unknown")
          )
        ]
      ])
    })
  }

  server_context_strings = {
    for key, ctx in local.server_context_text :
    key => merge(ctx, {
      bgp_local_info      = length(ctx.local_info_lines) > 0 ? join("\n", ctx.local_info_lines) : null
      bgp_remote_info     = length(ctx.remote_info_lines) > 0 ? join("\n", ctx.remote_info_lines) : null
      bgp_connection_info = length(ctx.connection_info_lines) > 0 ? join("\n", ctx.connection_info_lines) : null
      bgp_routes_info     = length(ctx.routes_info_lines) > 0 ? join("\n", ctx.routes_info_lines) : null
      bgp_session_map_json = length(ctx.remote_peer_map) > 0 ? jsonencode({
        for map_key, s in ctx.remote_peer_map :
        map_key => {
          remote_ip      = s.remote_ip
          remote_ip_type = s.remote_ip_type
          status         = s.status
          description    = s.description
          group_name     = s.group_name
          group_id       = s.group_id
          provider_asn   = s.provider_asn
        }
      }) : ""
      bgp_session_details_json = length(ctx.session_details_extended) > 0 ? jsonencode(ctx.session_details_extended) : ""
    })
  }

  server_comment_sections = {
    for key, ctx in local.server_context_strings :
    key => compact([
      join("\n", [
        "NetActuate Server Details:",
        format("  Server ID: %s", ctx.server.id),
        format("  Contract ID: %s", ctx.server.contract_id),
        format("  Location ID: %s", ctx.server.location_id),
        format("  Image: %s (ID %s)", ctx.server.image, ctx.server.image_id),
        format("  IPv4 Prefix: %s", var.bgp_ipv4_prefix)
      ]),
      ctx.bgp_local_info != null ? join("\n", [
        "BGP Local Info:",
        format("  %s", replace(ctx.bgp_local_info, "\n", "\n  "))
      ]) : null,
      ctx.bgp_remote_info != null ? join("\n", [
        "BGP Remote Info:",
        format("  %s", replace(ctx.bgp_remote_info, "\n", "\n  "))
      ]) : null,
      ctx.bgp_connection_info != null ? join("\n", [
        "BGP Connection Status:",
        format("  %s", replace(ctx.bgp_connection_info, "\n", "\n  "))
      ]) : null,
      ctx.bgp_routes_info != null ? join("\n", [
        "BGP Routes:",
        format("  %s", replace(ctx.bgp_routes_info, "\n", "\n  "))
      ]) : null,
      ctx.bgp_session_map_json != "" ? join("\n", [
        "BGP Sessions JSON:",
        format("  %s", replace(ctx.bgp_session_map_json, "\n", "\n  "))
      ]) : null,
      ctx.bgp_session_details_json != "" ? join("\n", [
        "BGP Session Details JSON:",
        format("  %s", replace(ctx.bgp_session_details_json, "\n", "\n  "))
      ]) : null
    ])
  }

  server_context_comments = {
    for key, ctx in local.server_context_strings :
    key => merge(ctx, {
      comment_sections = local.server_comment_sections[key]
      vm_comments      = length(local.server_comment_sections[key]) > 0 ? trimspace(join("\n\n", local.server_comment_sections[key])) : null
    })
  }

  server_context_final = local.server_context_comments

}

########################################
# NetBox core objects
########################################

resource "netbox_site" "this" {
  name        = var.pop_code
  slug        = lower(var.pop_code)
  description = "NetActuate PoP ${var.pop_code}"
  status      = "active"
}

resource "netbox_cluster" "this" {
  name            = "${var.pop_code}-cluster"
  cluster_type_id = var.cluster_type_id
  site_id         = netbox_site.this.id
}

resource "netbox_device" "vm" {
  for_each = var.servers

  name           = each.value.hostname
  device_type_id = var.device_type_id
  role_id        = var.device_role_id
  site_id        = netbox_site.this.id
  status         = "active"
  tags           = var.vm_tags
}

resource "netbox_virtual_machine" "vm" {
  for_each = var.servers

  name         = each.value.hostname
  site_id      = netbox_site.this.id
  cluster_id   = netbox_cluster.this.id
  status       = "active"
  vcpus        = each.value.vcpus
  memory_mb    = each.value.memory_mb
  disk_size_mb = each.value.disk_mb
  tags         = var.vm_tags

  description = format("NetActuate plan %s", each.value.plan)
  comments    = local.server_context_final[each.key].vm_comments

  custom_fields = {
    na_server_id           = each.value.id
    na_contract_id         = each.value.contract_id
    na_asn                 = tostring(var.asn)
    na_bgp_ipv4_prefix     = var.bgp_ipv4_prefix
    na_plan                = each.value.plan
    na_plan_id             = each.value.plan_id
    na_image_id            = each.value.image_id
    na_image               = each.value.image
    na_location_id         = each.value.location_id
    na_public_ipv4         = try(local.server_context_final[each.key].pub_v4_clean, "")
    na_public_ipv6         = try(local.server_context_final[each.key].pub_v6_clean, "")
    na_bgp_peers           = try(local.server_context_final[each.key].bgp_session_map_json, "")
    na_bgp_session_details = try(local.server_context_final[each.key].bgp_session_details_json, "")
    zz_bgp_local_info      = try(local.server_context_final[each.key].bgp_local_info, "")
    zz_bgp_remote_info     = try(local.server_context_final[each.key].bgp_remote_info, "")
    zz_bgp_connection_info = try(local.server_context_final[each.key].bgp_connection_info, "")
    zz_bgp_routes_info     = try(local.server_context_final[each.key].bgp_routes_info, "")
  }
}

resource "netbox_interface" "eth0" {
  for_each = var.servers

  name               = "eth0"
  virtual_machine_id = netbox_virtual_machine.vm[each.key].id
  enabled            = true
}

resource "netbox_service" "bgp179" {
  for_each = var.servers

  name               = "bgp"
  protocol           = "tcp"
  ports              = [179]
  virtual_machine_id = netbox_virtual_machine.vm[each.key].id
  description        = "Anycast ingress BGP (TCP/179)"
}

resource "netbox_ip_address" "public_v4" {
  for_each = var.servers

  ip_address = format("%s/32", trimspace(var.servers[each.key].public_ipv4))
  status     = "active"
  dns_name   = var.servers[each.key].hostname

  virtual_machine_interface_id = netbox_interface.eth0[each.key].id
}

resource "netbox_ip_address" "public_v6" {
  for_each = var.bgp_enable_ipv6 ? var.servers : {}

  ip_address = format("%s/128", trimspace(var.servers[each.key].public_ipv6))
  status     = "active"
  dns_name   = var.servers[each.key].hostname

  virtual_machine_interface_id = netbox_interface.eth0[each.key].id
}

resource "netbox_primary_ip" "vm_primary_v4" {
  for_each = var.servers

  virtual_machine_id = netbox_virtual_machine.vm[each.key].id
  ip_address_id      = netbox_ip_address.public_v4[each.key].id
  ip_address_version = 4
}

########################################
# Remote peer IPs and BGP session records
########################################
