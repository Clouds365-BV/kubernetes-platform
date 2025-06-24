terraform {
  required_version = "~> 1.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = "1cb334ab-9820-4ac2-b59a-1e2f7afd1f72"
}
