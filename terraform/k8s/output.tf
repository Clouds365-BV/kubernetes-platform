output "environment_name" {
  value = var.env.name
}

output "k8s_key_vault_secrets_provider_identity" {
  value = data.azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0]
}