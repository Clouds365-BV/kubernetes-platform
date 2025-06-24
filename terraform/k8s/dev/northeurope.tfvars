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
    sku_name          = "PerGB2018"
    retention_in_days = 31
  }

  application_insights = {
    log_analytics_workspace = "main"
    application_type        = "web"
    retention_in_days       = 31
  }

  vnet = {
    address_space = ["10.10.0.0/16"]
    subnets = {
      "mysql-flexible-server" = {
        address_prefixes = ["10.10.20.0/24"]
        delegations = {
          main = {
            name    = "Microsoft.DBforMySQL/flexibleServers"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        }
        service_endpoints = ["Microsoft.Storage"]
      }
      "k8s" = {
        address_prefixes  = ["10.10.30.0/24"]
        service_endpoints = ["Microsoft.KeyVault"]
      }
    }
  }

  private_dns_zone = {}

  public_ips = {}

  bastion_hosts = {}

  identity = {}

  key_vault = {
    sku_name                      = "standard"
    public_network_access_enabled = true
    secrets = {
      "database-admin-username" = {
        value = "mysqladmin"
      }
      "database-admin-password" = {
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
}

