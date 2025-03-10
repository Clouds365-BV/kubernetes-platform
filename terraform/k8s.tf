resource "azurerm_user_assigned_identity" "k8s" {
  name                = "${local.resource_name_prefix}-k8s-id"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_role_assignment" "k8s" {
  scope                = azurerm_private_dns_zone.this["privatelink.northeurope.azmk8s.io"].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.k8s.principal_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = "${local.resource_name_prefix}-k8s"
  location                          = azurerm_resource_group.this.location
  resource_group_name               = azurerm_resource_group.this.name
  dns_prefix                        = "${local.resource_name_prefix}-k8s"
  workload_identity_enabled         = true
  private_cluster_enabled           = true
  private_dns_zone_id               = azurerm_private_dns_zone.this["privatelink.northeurope.azmk8s.io"].id
  local_account_disabled            = true
  role_based_access_control_enabled = true
  kubernetes_version                = "1.28"
  oidc_issuer_enabled               = true

  default_node_pool {
    name                 = "system"
    vm_size              = "Standard_D2s_v6"
    vnet_subnet_id       = azurerm_subnet.this["k8s"].id
    min_count            = 1
    max_count            = 10
    auto_scaling_enabled = true
    orchestrator_version = "1.28"
    tags                 = local.tags
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.k8s.id
    ]
  }

  lifecycle {
    ignore_changes = [location, disk_encryption_set_id, identity]
  }

  tags = local.tags
}
