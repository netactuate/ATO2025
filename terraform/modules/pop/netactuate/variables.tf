variable "pop_code" {
  description = "PoP code used for naming resources, e.g., RDU"
  type        = string
}

variable "hostname_prefix" {
  description = "Hostname prefix for the NetActuate server"
  type        = string
}

variable "location_id" {
  description = "NetActuate location identifier"
  type        = number
}

variable "plan" {
  description = "NetActuate plan string, e.g., VR1x1x25"
  type        = string
}

variable "worker_count" {
  description = "Number of NetActuate servers to create for this PoP"
  type        = number
  default     = 1
}

variable "image_id" {
  description = "NetActuate image identifier"
  type        = number
}

variable "contract_id" {
  description = "NetActuate contract identifier"
  type        = number
}

variable "ssh_key_id" {
  description = "NetActuate SSH key identifier"
  type        = number
}

variable "bgp_group_id" {
  description = "Optional provider-side BGP group identifier"
  type        = number
  default     = null
}

variable "bgp_enable_ipv6" {
  description = "Enable IPv6 when building NetActuate BGP sessions"
  type        = bool
  default     = false
}

variable "enable_bgp_sessions" {
  description = "Manage provider-side BGP sessions for this server"
  type        = bool
  default     = true
}
