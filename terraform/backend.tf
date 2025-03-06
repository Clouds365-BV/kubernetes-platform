terraform {
  required_version = "~> 1.11.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # azuread = {
    #   source  = "hashicorp/azuread"
    #   version = "~> 3.0"
    # }
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.0"
    # }
    # azapi = {
    #   source  = "azure/azapi"
    #   version = "~> 2.0"
    # }
  }
}

terraform {
  backend "azurerm" {
    #subscription_id = "1cb334ab-9820-4ac2-b59a-1e2f7afd1f72"
    #resource_group_name  = "terraform"
    #storage_account_name = "ncterraform"
    #container_name       = "state"
    #key                  = "drone-dev-northeurope.tfstate"
  }
}

provider "azurerm" {
  #subscription_id = "1cb334ab-9820-4ac2-b59a-1e2f7afd1f72"
  features {}
}
