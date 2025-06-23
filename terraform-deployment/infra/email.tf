resource "azurerm_email_communication_service" "this" {
  name                = "${local.resource_name_prefix}-email"
  resource_group_name = azurerm_resource_group.this.name
  data_location       = "Europe"

  tags = local.tags
}

resource "azurerm_email_communication_service_domain" "this" {
  name              = "AzureManagedDomain"
  email_service_id  = azurerm_email_communication_service.this.id
  domain_management = "AzureManaged"

  tags = local.tags
}