variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "customer_prefix" {
  description = "The customer prefix used to name resources"
  type        = string
  default     = "drones"
}

variable "env" {
  description = "The environment configuration"
  type = object({
    env_name = string
    location = string
    vnet = object({
      address_space = list(string)
      subnets       = map(any)
    })
    private_dns_zone = map(string)
    databases        = map(any)
  })
}

variable "k8s_admin_group_id" {
  description = "The object ID of the Azure AD group for Kubernetes administrators"
  type        = string
}

variable "regions" {
  description = "The regions to deploy resources to"
  type = map(object({
    location = string
    vnet = object({
      address_space = list(string)
      subnets = map(object({
        address_prefixes  = list(string)
        service_endpoints = optional(list(string), [])
        delegations = optional(map(object({
          name    = string
          actions = list(string)
        })), {})
      }))
    })
    service_cidr   = string
    dns_service_ip = string
  }))
  default = {
    "primary" = {
      location = "northeurope"
      vnet = {
        address_space = ["10.0.0.0/16"]
        subnets = {
          "k8s" = {
            address_prefixes  = ["10.0.0.0/22"]
            service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
          }
          "agw" = {
            address_prefixes = ["10.0.4.0/24"]
          }
          "endpoints" = {
            address_prefixes = ["10.0.5.0/24"]
          }
          "databases" = {
            address_prefixes = ["10.0.6.0/24"]
            delegations = {
              "mysql" = {
                name    = "Microsoft.DBforMySQL/flexibleServers"
                actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
              }
            }
          }
        }
      }
      service_cidr   = "10.2.0.0/16"
      dns_service_ip = "10.2.0.10"
    }
    "secondary" = {
      location = "westeurope"
      vnet = {
        address_space = ["10.1.0.0/16"]
        subnets = {
          "k8s" = {
            address_prefixes  = ["10.1.0.0/22"]
            service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
          }
          "agw" = {
            address_prefixes = ["10.1.4.0/24"]
          }
          "endpoints" = {
            address_prefixes = ["10.1.5.0/24"]
          }
          "databases" = {
            address_prefixes = ["10.1.6.0/24"]
            delegations = {
              "mysql" = {
                name    = "Microsoft.DBforMySQL/flexibleServers"
                actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
              }
            }
          }
        }
      }
      service_cidr   = "10.3.0.0/16"
      dns_service_ip = "10.3.0.10"
    }
  }
}
