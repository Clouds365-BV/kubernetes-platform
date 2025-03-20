module "k8s-kv-roles" {
  source = "../../modules/azure/authorization/role-assignment"
  for_each = {
    "key_vault|Key Vault Reader" : azurerm_key_vault.this.id,
    "key_vault|Key Vault Secrets User" : azurerm_key_vault.this.id
  }

  object_id            = azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name = split("|", each.key)[1]
  resource_id          = each.value
}
