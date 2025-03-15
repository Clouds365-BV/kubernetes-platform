data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_cluster" "this" {
  name                = azurerm_kubernetes_cluster.this.name
  resource_group_name = azurerm_kubernetes_cluster.this.resource_group_name
}
