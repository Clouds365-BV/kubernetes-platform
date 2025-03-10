resource "azurerm_resource_group" "this" {
  name     = "${local.resource_name_prefix}-rg"
  location = var.location

  tags = local.tags
}

resource "azurerm_storage_account" "this" {
  name                     = replace(replace("${local.resource_name_prefix}-st", "-", ""), "_", "")
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}
