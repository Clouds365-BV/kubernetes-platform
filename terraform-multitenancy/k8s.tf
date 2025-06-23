resource "azurerm_user_assigned_identity" "k8s" {
  for_each = var.regions

  name                = "${local.resource_name_prefix}-${each.key}-k8s-id"
  resource_group_name = azurerm_resource_group.this[each.key].name
  location            = azurerm_resource_group.this[each.key].location

  tags = local.tags
}

module "k8s-roles" {
  source = "../modules/azure/authorization/role-assignment"
  for_each = {
    for x in flatten([
      for region_key, region in var.regions : [
        for dns_zone_key, dns_zone_id in {
          "Private DNS Zone Contributor" = azurerm_private_dns_zone.this["privatelink.${region.location}.azmk8s.io"].id
          } : {
          region_key  = region_key
          role_key    = dns_zone_key
          resource_id = dns_zone_id
        }
      ]
    ]) : "${x.region_key}-${x.role_key}" => x
  }

  object_id            = azurerm_user_assigned_identity.k8s[each.value.region_key].principal_id
  role_definition_name = each.value.role_key
  resource_id          = each.value.resource_id
}

resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.regions

  #checkov:skip=CKV_AZURE_116: "Ensure that AKS uses Azure Policies Add-on"
  #checkov:skip=CKV_AZURE_117: "Ensure that AKS use the Paid Sku for its SLA"
  #checkov:skip=CKV_AZURE_170: "Ensure that AKS uses disk encryption set"
  #checkov:skip=CKV_AZURE_226: "Ensure ephemeral disks are used for OS disks"
  name                      = "${local.resource_name_prefix}-${each.key}-k8s"
  location                  = azurerm_resource_group.this[each.key].location
  resource_group_name       = azurerm_resource_group.this[each.key].name
  dns_prefix                = "${local.resource_name_prefix}-${each.key}-k8s"
  workload_identity_enabled = true
  workload_autoscaler_profile {
    keda_enabled = true
  }
  kubernetes_version                = "1.30"
  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  automatic_upgrade_channel         = "patch"
  node_os_upgrade_channel           = "SecurityPatch"
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 168
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.this[each.key].id
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = [
      var.k8s_admin_group_id
    ]
  }
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this[each.key].id
  }
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = each.value.service_cidr
    dns_service_ip = each.value.dns_service_ip
  }
  storage_profile {
    file_driver_enabled = true
  }

  default_node_pool {
    name                        = "system"
    temporary_name_for_rotation = "systemrot"
    vm_size                     = "Standard_D2s_v6"
    vnet_subnet_id              = azurerm_subnet.this["${each.key}-k8s"].id
    min_count                   = 2
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
      "drones/region"   = each.key
    }

    tags = local.tags
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.k8s[each.key].id
    ]
  }

  depends_on = [
    module.k8s-roles
  ]

  tags = local.tags
}

# Node pools for multi-tenancy and workload segregation
resource "azurerm_kubernetes_cluster_node_pool" "general" {
  for_each = var.regions

  name                    = "general"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this[each.key].id
  vm_size                 = "Standard_D4s_v6"
  vnet_subnet_id          = azurerm_subnet.this["${each.key}-k8s"].id
  min_count               = 2
  max_count               = 6
  auto_scaling_enabled    = true
  orchestrator_version    = "1.30"
  max_pods                = 110
  host_encryption_enabled = true

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "20%"
    node_soak_duration_in_minutes = 0
  }

  node_labels = {
    "drones/nodepool" = "general"
    "drones/workload" = "ghost"
    "drones/region"   = each.key
  }

  node_taints = [
    "drones/workload=ghost:NoSchedule"
  ]

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "team1" {
  for_each = var.regions

  name                    = "team1"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this[each.key].id
  vm_size                 = "Standard_D4s_v6"
  vnet_subnet_id          = azurerm_subnet.this["${each.key}-k8s"].id
  min_count               = 1
  max_count               = 3
  auto_scaling_enabled    = true
  orchestrator_version    = "1.30"
  max_pods                = 110
  host_encryption_enabled = true

  node_labels = {
    "drones/nodepool" = "team1"
    "drones/team"     = "team1"
    "drones/region"   = each.key
  }

  node_taints = [
    "drones/team=team1:NoSchedule"
  ]

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "team2" {
  for_each = var.regions

  name                    = "team2"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this[each.key].id
  vm_size                 = "Standard_D4s_v6"
  vnet_subnet_id          = azurerm_subnet.this["${each.key}-k8s"].id
  min_count               = 1
  max_count               = 3
  auto_scaling_enabled    = true
  orchestrator_version    = "1.30"
  max_pods                = 110
  host_encryption_enabled = true

  node_labels = {
    "drones/nodepool" = "team2"
    "drones/team"     = "team2"
    "drones/region"   = each.key
  }

  node_taints = [
    "drones/team=team2:NoSchedule"
  ]

  tags = local.tags
}

module "diagnostic_settings_aks" {
  source = "../modules/azure/monitor/diagnostic-settings"

  name                       = "aks-diagnostic-settings"
  target_resource_id         = azurerm_kubernetes_cluster.this["primary"].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this["primary"].id
  logs                       = local.diagnostic_settings.logs
  metrics                    = local.diagnostic_settings.metrics
}
