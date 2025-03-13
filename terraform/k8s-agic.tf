resource "azurerm_user_assigned_identity" "k8s-agic" {
  name                = "${local.resource_name_prefix}-k8s-agic-id"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_role_assignment" "k8s-agic" {
  scope                = azurerm_application_gateway.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.k8s-agic.principal_id
}

resource "helm_release" "agic" {
  name       = "agic"
  repository = "https://azure.github.io/application-gateway-kubernetes-ingress/"
  chart      = "ingress-azureapplicationgateway"
  namespace  = "kube-system"

  set {
    name  = "appgw.subscriptionId"
    value = data.azurerm_client_config.current.subscription_id
  }

  set {
    name  = "appgw.resourceGroup"
    value = azurerm_resource_group.this.name
  }

  set {
    name  = "appgw.name"
    value = azurerm_application_gateway.this.name
  }

  set {
    name  = "kubernetes.watchNamespace"
    value = "*" # Or a specific namespace where your application resides.
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }
}
