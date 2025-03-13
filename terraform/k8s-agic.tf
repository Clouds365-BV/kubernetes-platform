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
  repository = "oci://mcr.microsoft.com/azure-application-gateway/charts"
  chart      = "ingress-azure"
  namespace  = "kube-system"

  set {
    name  = "appgw.applicationGatewayID"
    value = azurerm_application_gateway.this.id
  }

  set {
    name  = "armAuth.type"
    value = "workloadIdentity"
  }

  set {
    name  = "armAuth.identityClientID"
    value = azurerm_user_assigned_identity.k8s-agic.principal_id
  }

  set {
    name  = "rbac.enabled"
    value = "true"
  }
}
