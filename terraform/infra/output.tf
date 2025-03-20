output "environment_name" {
  value = var.env.name
}

output "k8s_ingress_application_gateway_identity" {
  value = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0]
}

output "k8s_key_vault_secrets_provider_identity" {
  value = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0]
}