data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "this" {
  name                = "${local.resource_name_prefix}-kv"
  resource_group_name = "${local.resource_name_prefix}-rg"
}

data "azurerm_kubernetes_cluster" "this" {
  name                = "${local.resource_name_prefix}-k8s"
  resource_group_name = "${local.resource_name_prefix}-rg"
}
