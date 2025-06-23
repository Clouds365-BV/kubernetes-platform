locals {
  resource_name_prefix = "${var.project_name}-${var.env.name_short}-${var.env.location_short}"

  tags = var.env.tags
}