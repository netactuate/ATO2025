# variables.tf (fixed)

variable "netbox_url" {
  type        = string
  description = "NetBox base URL (e.g., http://104.225.115.196)"
}

variable "netbox_token" {
  type        = string
  description = "NetBox API token"
  sensitive   = true
}

variable "contract_id" {
  type        = number
  description = "NetActuate Contract ID"
  default     = 440
}

variable "bgp_asn" {
  type        = number
  description = "Local ASN for the demo"
  default     = 63911
}

variable "bgp_peer_asn" {
  type        = number
  description = "Remote peer ASN documented in NetBox BGP sessions"
  default     = 36236
}

variable "bgp_ipv4_prefix" {
  type        = string
  description = "Anycast IPv4 prefix to document in NetBox"
  default     = "45.54.50.0/24"
}

# Ubuntu 24.04 LTS (20240423)
variable "image_id" {
  type        = number
  description = "NetActuate image_id to use"
  default     = 5787
}

# Optional: actually create provider-side BGP sessions (set a real group_id)
variable "bgp_group_id" {
  type        = number
  description = "Provider BGP group_id; null = skip creating sessions"
  default     = null
}

variable "bgp_enable_ipv6" {
  type        = bool
  description = "Enable IPv6 on provider-side BGP sessions (if created)"
  default     = true
}

# PoPs to deploy. 'plan' defaults to VR1x1x25 and can be overridden per PoP.
variable "pops" {
  description = "Map of PoPs to deploy"
  type = map(object({
    location_id     = number
    plan            = optional(string, "VR1x1x25")
    hostname_prefix = optional(string, "anycast-ingress")
    worker_count    = optional(number, 1)
  }))
  default = {
    RDU  = { location_id = 236, worker_count = 2 }
    IAD3 = { location_id = 245, worker_count = 1 }
    CHI  = { location_id = 31, worker_count = 1 }
    #    DEN  = { location_id = 122, worker_count = 1 }
    #    PDX  = { location_id = 571, worker_count = 1 } # PDX - Portland, OR
    #    SEA  = { location_id = 124, worker_count = 1 } # SEA - Seattle, WA
  }
}

variable "static_bgp_peers" {
  description = "Static map of PoP code -> expected IPv4/IPv6 peer addresses"
  type = map(object({
    ipv4 = optional(list(string), [])
    ipv6 = optional(list(string), [])
  }))
  default = {}
}

# How we authenticate console access on created servers
variable "ssh_key_id" {
  type        = number
  description = "Existing NetActuate SSH key ID (alternative to ssh_public_key)"
  default     = 8199
}

variable "ssh_public_key" {
  type        = string
  description = "Public key to create in NetActuate if ssh_key_id is not provided (e.g., 'ssh-ed25519 AAAA... user@host')"
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVO1bAvpODeyDeUYlue3O7RODBXJp/wHFHgf0j6TFrZ cjackson@netactuate.com"
}
