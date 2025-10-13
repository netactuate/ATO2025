variable "pop_code" {
  description = "PoP code mirrored into NetBox site and naming"
  type        = string
}

variable "cluster_type_id" {
  description = "NetBox cluster type identifier"
  type        = number
}

variable "device_role_id" {
  description = "NetBox device role identifier"
  type        = number
}

variable "device_type_id" {
  description = "NetBox device type identifier"
  type        = number
}

variable "vm_tags" {
  description = "NetBox tag names applied to mirrored objects"
  type        = list(string)
  default     = []
}

variable "asn" {
  description = "Local ASN used for metadata"
  type        = number
}

variable "bgp_ipv4_prefix" {
  description = "Anycast IPv4 prefix tracked in NetBox"
  type        = string
}

variable "local_as_id" {
  description = "NetBox ASN ID representing the local ASN"
  type        = number
}

variable "remote_as_id" {
  description = "NetBox ASN ID representing the upstream/remote ASN"
  type        = number
}

variable "static_bgp_peers" {
  description = "Static BGP peer addresses to seed when sessions are not yet available"
  type = object({
    ipv4 = list(string)
    ipv6 = list(string)
  })
  default = {
    ipv4 = []
    ipv6 = []
  }
}

variable "enable_bgp_sessions" {
  description = "Manage NetBox BGP session plugin records"
  type        = bool
  default     = true
}

variable "bgp_enable_ipv6" {
  description = "Whether IPv6 BGP is enabled (used to create IPv6 IP objects)"
  type        = bool
  default     = true
}

variable "bgp_session_status" {
  description = "Default NetBox BGP session status when state data is unavailable"
  type        = string
  default     = "active"
}

variable "servers" {
  description = "Map of worker key -> NetActuate server facts"
  type        = map(any)
}

variable "netbox_url" {
  description = "Base URL for the NetBox API"
  type        = string
}

variable "netbox_token" {
  description = "API token for NetBox authentication"
  type        = string
  sensitive   = true
}
