variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "env" {
  type = any
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}
