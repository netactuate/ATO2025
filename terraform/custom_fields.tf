# Custom fields used on Virtual Machines
locals {
  vm_ct = ["virtualization.virtualmachine"]
}

resource "netbox_custom_field" "na_server_id" {
  name          = "na_server_id"
  label         = "NetActuate Server ID"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_contract_id" {
  name          = "na_contract_id"
  label         = "NetActuate Contract ID"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_asn" {
  name          = "na_asn"
  label         = "NetActuate ASN"
  type          = "text" # <— IMPORTANT: provider sends strings
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_bgp_ipv4_prefix" {
  name          = "na_bgp_ipv4_prefix"
  label         = "BGP IPv4 Prefix"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_plan" {
  name          = "na_plan"
  label         = "Plan"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_plan_id" {
  name          = "na_plan_id"
  label         = "Plan ID"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_image_id" {
  name          = "na_image_id"
  label         = "Image ID"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_image" {
  name          = "na_image"
  label         = "Image"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_location_id" {
  name          = "na_location_id"
  label         = "Location ID"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_public_ipv4" {
  name          = "na_public_ipv4"
  label         = "Public IPv4"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_public_ipv6" {
  name          = "na_public_ipv6"
  label         = "Public IPv6"
  type          = "text"
  content_types = local.vm_ct
}

# Temporary - bring back just to clear state, then remove
resource "netbox_custom_field" "na_bgp_peers" {
  name          = "na_bgp_peers"
  label         = "BGP Peers (JSON)"
  type          = "text"
  content_types = local.vm_ct
}

resource "netbox_custom_field" "na_bgp_session_details" {
  name          = "na_bgp_session_details"
  label         = "NetActuate BGP Session Details"
  type          = "text"
  content_types = local.vm_ct
}

# BGP breakdown fields for VM page visibility
resource "netbox_custom_field" "zz_bgp_local_info" {
  name          = "zz_bgp_local_info"
  label         = "BGP Local Info"
  type          = "text"
  content_types = local.vm_ct
  description   = "Local BGP session information (hostname, ASN, IPs)"
}

resource "netbox_custom_field" "zz_bgp_remote_info" {
  name          = "zz_bgp_remote_info"
  label         = "BGP Remote Info"
  type          = "text"
  content_types = local.vm_ct
  description   = "Remote BGP peer information (group, ASN, IPs)"
}

resource "netbox_custom_field" "zz_bgp_connection_info" {
  name          = "zz_bgp_connection_info"
  label         = "BGP Connection Info"
  type          = "text"
  content_types = local.vm_ct
  description   = "BGP session connection status and timestamps"
}

resource "netbox_custom_field" "zz_bgp_routes_info" {
  name          = "zz_bgp_routes_info"
  label         = "BGP Routes Info"
  type          = "text"
  content_types = local.vm_ct
  description   = "BGP routes received and advertised"
}
