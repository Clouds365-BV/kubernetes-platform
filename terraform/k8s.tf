resource "azurerm_user_assigned_identity" "k8s" {
  name                = "${local.resource_name_prefix}-k8s-id"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = local.tags
}

module "k8s-roles" {
  source = "../modules/azure/authorization/role-assignment"

  object_id            = azurerm_user_assigned_identity.k8s.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  resource_id          = azurerm_private_dns_zone.this["privatelink.northeurope.azmk8s.io"].id
}

resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_116: "Ensure that AKS uses Azure Policies Add-on"
  #checkov:skip=CKV_AZURE_117: "Ensure that AKS use the Paid Sku for its SLA"
  #checkov:skip=CKV_AZURE_170: "Ensure that AKS uses disk encryption set"
  #checkov:skip=CKV_AZURE_226: "Ensure ephemeral disks are used for OS disks"
  name                      = "${local.resource_name_prefix}-k8s"
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_prefix                = "${local.resource_name_prefix}-k8s"
  workload_identity_enabled = true
  private_cluster_enabled   = true
  #private_cluster_public_fqdn_enabled = true
  private_dns_zone_id               = azurerm_private_dns_zone.this["privatelink.northeurope.azmk8s.io"].id
  kubernetes_version                = "1.30"
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  automatic_upgrade_channel         = "patch"
  node_os_upgrade_channel           = "SecurityPatch"
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 168
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.this.id
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = [
      "4231288e-ea6d-46c4-8e2d-58bcdf884831"
    ]
  }
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
  #azure_policy_enabled = true

  default_node_pool {
    name                        = "system"
    temporary_name_for_rotation = "systemrot"
    vm_size                     = "Standard_D2s_v6"
    vnet_subnet_id              = azurerm_subnet.this["k8s"].id
    min_count                   = 1
    max_count                   = 3
    auto_scaling_enabled        = true
    orchestrator_version        = "1.30"
    max_pods                    = 50
    host_encryption_enabled     = true
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }

    node_labels = {
      "drones/nodepool" = "system"
    }

    tags = local.tags
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.k8s.id
    ]
  }

  depends_on = [
    module.k8s-roles
  ]

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "blog" {
  name                        = "blog"
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.this.id
  vnet_subnet_id              = azurerm_subnet.this["k8s"].id
  temporary_name_for_rotation = "blogrot"
  vm_size                     = "Standard_D2s_v6"
  min_count                   = 1
  max_count                   = 5
  auto_scaling_enabled        = true
  orchestrator_version        = "1.30"
  host_encryption_enabled     = true
  fips_enabled                = false
  node_public_ip_enabled      = false
  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  node_labels = {
    "drones/nodepool" = "blog"
  }

  tags = local.tags
}
