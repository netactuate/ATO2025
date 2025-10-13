terraform {
  required_version = ">= 1.5.0"

  required_providers {
    netactuate = {
      source  = "netactuate/netactuate"
      version = "~> 0.2"
    }
  }
}
