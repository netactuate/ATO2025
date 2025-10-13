provider "netactuate" {
  # reads NETACTUATE_API_KEY from environment
  # api_url = "https://api.netactuate.com" # optional override
}

variable "netbox_insecure" {
  type        = bool
  description = "Set true if NetBox is http or has self-signed cert"
  default     = true
}

provider "netbox" {
  server_url           = var.netbox_url
  api_token            = var.netbox_token
  allow_insecure_https = var.netbox_insecure
}

provider "netboxbgp" {
  server_url           = var.netbox_url
  api_token            = var.netbox_token
  allow_insecure_https = var.netbox_insecure
}
