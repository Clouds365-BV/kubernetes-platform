# Environment Configuration
env = {
  name           = "development"
  name_short     = "dev"
  location_short = "ne"

  tags = {
    Environment = "development"
    Owner       = "Drone Shuttles"
    Project     = "Ghost"
  }

  log_analytics_workspace = {
    sku_name          = "PerGB2018$"
    retention_in_days = 31
  }

  application_insights = {
    log_analytics_workspace = "main"
    application_type        = "web"
    retention_in_days       = 31
  }

  vnets = {
    primary = {
      address_space = ["10.0.0.0/16"]
      subnets = {
        k8s = {
          address_prefixes  = ["10.0.0.0/22"]
          service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
        }
        agw = {
          address_prefixes = ["10.0.4.0/24"]
        }
        endpoints = {
          address_prefixes = ["10.0.5.0/24"]
        }
        databases = {
          address_prefixes = ["10.0.6.0/24"]
          delegations = {
            main = {
              name    = "Microsoft.DBforMySQL/flexibleServers"
              actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
          service_endpoints = ["Microsoft.Storage"]
        }
        service_cidr   = "10.2.0.0/16"
        dns_service_ip = "10.2.0.10"
      }
    }
    secondary = {
      location      = "westeurope"
      address_space = ["10.1.0.0/16"]
      subnets = {
        k8s = {
          address_prefixes  = ["10.1.0.0/22"]
          service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
        }
        agw = {
          address_prefixes = ["10.1.4.0/24"]
        }
        endpoints = {
          address_prefixes = ["10.1.5.0/24"]
        }
        databases = {
          address_prefixes = ["10.1.6.0/24"]
          delegations = {
            main = {
              name    = "Microsoft.DBforMySQL/flexibleServers"
              actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
            }
          }
          service_endpoints = ["Microsoft.Storage"]
        }
      }
    }
    service_cidr   = "10.3.0.0/16"
    dns_service_ip = "10.3.0.10"
  }

  private_dns_zones = {
    "privatelink.mysql.database.azure.com" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.northeurope.azmk8s.io" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.blob.core.windows.net" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.table.core.windows.net" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.queue.core.windows.net" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.file.core.windows.net" = {
      virtual_networks = {
        main = {}
      }
    }
    "privatelink.vault.azure.net" = {
      virtual_networks = {
        main = {}
      }
    }
  }

  public_ips = {
    bastion = {
      sku               = "Standard"
      allocation_method = "Static"
    }
    app_gateway = {
      sku               = "Standard"
      allocation_method = "Static"
    }
  }

  bastion_hosts = {
    org = {
      sku               = "Standard"
      tunneling_enabled = true
      subnet            = "bastion"
      public_ip         = "bastion"
    }
  }

  identities = {}

  key_vault = {
    sku_name                      = "standard"
    public_network_access_enabled = true
    secrets = {
      database-admin-username = {
        value = "mysqladmin"
      }
      database-admin-password = {
        length = 24
      }
    }
  }

  databases = {
    mysql = {
      sku_name                      = "B_Standard_B1ms"
      storage_gb                    = 32
      version                       = "8.0.21"
      subnet                        = "mysql-flexible-server"
      public_network_access_enabled = false
      administrator_login           = "database-admin-username"
      administrator_password        = "database-admin-password"
      parameters = {
        require_secure_transport = "ON"
        tls_version              = "TLSv1.3"
      }
      databases = {
        drone = {}
      }
    }
  }

  k8s_admin_group_id = "4231288e-ea6d-46c4-8e2d-58bcdf884831"
}
