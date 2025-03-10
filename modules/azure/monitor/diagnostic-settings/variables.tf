variable "name" {
  type = string
}

variable "target_resource_id" {
  description = "The ID of an existing Resource on which to configure Diagnostic Settings. Changing this forces a new resource to be created."
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "logs" {
  type        = list(any)
  description = "An array of diagnostic logs to configure."
}

variable "metrics" {
  type        = list(any)
  description = "An array of diagnostic metrics to configure."
}
