variable "pop_code" {
  description = "PoP code (used for NetBox Site and naming), e.g., RDU, IAD3, CHI"
  type        = string
}

variable "location_id" {
  description = "NetActuate location_id for this PoP"
  type        = number
}

variable "plan" {
  description = "NetActuate VM plan/package string, e.g., VR1x1x25"
  type        = string
}

variable "image_id" {
  description = "NetActuate image_id (e.g., 5787 for Ubuntu 24.04 LTS)"
  type        = number
}

variable "hostname_prefix" {
  description = "Hostname prefix for the VM (e.g., anycast-ingress)"
  type        = string
}

variable "worker_count" {
  description = "Number of ECMP worker VMs to create in this PoP"
  type        = number
  default     = 1
}

variable "contract_id" {
  description = "NetActuate billing contract ID (e.g., 440)"
  type        = number
}

variable "asn" {
  description = "Local ASN (for metadata/custom fields)"
  type        = number
  default     = 63911
}

variable "bgp_ipv4_prefix" {
  description = "Documented anycast IPv4 prefix (for metadata/custom fields)"
  type        = string
}

variable "bgp_group_id" {
  description = "If set, create provider-side BGP sessions for this VM"
  type        = number
  default     = null
}

variable "bgp_enable_ipv6" {
  description = "Enable IPv6 when creating provider-side BGP sessions"
  type        = bool
  default     = false
}

variable "ssh_key_id" {
  description = "NetActuate SSH key ID to attach to the server"
  type        = number
}

variable "cluster_type_id" {
  description = "ID of the NetBox cluster type to use"
  type        = number
}

variable "vm_tags" {
  description = "List of NetBox tag names to apply to the VM"
  type        = list(string)
  default     = []
}

variable "static_bgp_peers" {
  description = "Static IPv4/IPv6 peer addresses to create in NetBox"
  type = object({
    ipv4 = list(string)
    ipv6 = list(string)
  })
  default = {
    ipv4 = []
    ipv6 = []
  }
}

variable "device_role_id" {
  description = "NetBox device role ID used for mirrored device objects"
  type        = number
}

variable "device_type_id" {
  description = "NetBox device type ID used for mirrored device objects"
  type        = number
}

variable "local_as_id" {
  description = "NetBox ASN ID representing the local ASN"
  type        = number
}

variable "remote_as_id" {
  description = "NetBox ASN ID representing the upstream/remote ASN"
  type        = number
}

variable "enable_bgp_sessions" {
  description = "Create NetBox BGP session records via plugin"
  type        = bool
  default     = true
}

variable "bgp_session_status" {
  description = "NetBox BGP session status value"
  type        = string
  default     = "active"
}

variable "netbox_url" {
  description = "NetBox API base URL for downstream modules"
  type        = string
}

variable "netbox_token" {
  description = "NetBox API token for downstream modules"
  type        = string
  sensitive   = true
}
