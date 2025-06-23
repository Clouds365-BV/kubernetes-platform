resource "kubernetes_manifest" "secrets_store_database" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "azure-database-kv"
      namespace = "blog"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity         = "false"
        useVMManagedIdentity   = "true"
        userAssignedIdentityID = data.azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id
        keyvaultName           = data.azurerm_key_vault.this.name
        objects                = <<-EOT
          array:
            - |
              objectName: database-host
              objectType: secret
              objectVersion: ""
            - |
              objectName: database-admin-username
              objectType: secret
              objectVersion: ""
            - |
              objectName: database-admin-password
              objectType: secret
              objectVersion: ""
            - |
              objectName: database-name
              objectType: secret
              objectVersion: ""
            - |
              objectName: database-ca-cert
              objectType: secret
              objectVersion: ""
        EOT
        tenantId               = data.azurerm_client_config.current.tenant_id
      }
      secretObjects = [
        {
          secretName = "database-connection"
          type       = "Opaque"
          data = [
            {
              objectName = "database-host"
              key        = "database__connection__host"
            },
            {
              objectName = "database-admin-username"
              key        = "database__connection__user"
            },
            {
              objectName = "database-admin-password"
              key        = "database__connection__password"
            },
            {
              objectName = "database-name"
              key        = "database__connection__database"
            },
            {
              objectName = "database-ca-cert"
              key        = "database__connection__ssl__ca"
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "secrets_store_smtp" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "azure-smtp-kv"
      namespace = "blog"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity         = "false"
        useVMManagedIdentity   = "true"
        userAssignedIdentityID = data.azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_identity[0].client_id
        keyvaultName           = data.azurerm_key_vault.this.name
        objects                = <<-EOT
          array:
            - |
              objectName: smtp-username
              objectType: secret
              objectVersion: ""
            - |
              objectName: smtp-password
              objectType: secret
              objectVersion: ""
        EOT
        tenantId               = data.azurerm_client_config.current.tenant_id
      }
      secretObjects = [
        {
          secretName = "smtp-connection"
          type       = "Opaque"
          data = [
            {
              objectName = "smtp-username"
              key        = "mail__options__auth__user"
            },
            {
              objectName = "smtp-password"
              key        = "mail__options__auth__pass"
            }
          ]
        }
      ]
    }
  }
}