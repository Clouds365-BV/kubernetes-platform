terraform {
  required_version = "~> 1.11.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "k8s"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "k8s"
  }
}
