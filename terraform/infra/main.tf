resource "azurerm_resource_group" "this" {
  name     = "${local.resource_name_prefix}-rg"
  location = var.location

  tags = local.tags
}

resource "azurerm_storage_account" "this" {
  #checkov:skip=CKV2_AZURE_1: "Ensure storage for critical data are encrypted with Customer Managed Key"
  name                            = replace(replace("${local.resource_name_prefix}-st", "-", ""), "_", "")
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags
}

resource "azurerm_storage_share" "example" {
  name               = "pv"
  storage_account_id = azurerm_storage_account.this.id
  quota              = 50
}