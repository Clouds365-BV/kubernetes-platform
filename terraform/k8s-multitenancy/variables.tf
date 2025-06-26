variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "customer_prefix" {
  description = "The customer prefix used to name resources"
  type        = string
  default     = "drones"
}

variable "env" {
  description = "The environment configuration"
  type        = any
}
