terraform {
  required_version = "~> 1.11.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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
  host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
}

# provider "helm" {
#   kubernetes {
#     host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
#     client_certificate     = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
#     client_key             = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
#     cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
#   }
# }

# provider "helm" {
#   debug = true
#   kubernetes {
#     host                   = data.azurerm_kubernetes_cluster.this.kube_config.0.host
#     cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "kubelogin"
#       args = [
#         "get-token",
#         "--login",
#         "spn",
#         "--server-id",
#         "6dae42f8–4368–4678–94ff-3960e28e3630",
#         "--use-azurerm-env-vars"
#       ]
#     }
#   }
# }
