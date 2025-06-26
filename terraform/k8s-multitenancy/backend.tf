terraform {
  required_version = "~> 1.0"

  backend "azurerm" {}

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

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.this["primary"].kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this["primary"].kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this["primary"].kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this["primary"].kube_config.0.cluster_ca_certificate)
}
