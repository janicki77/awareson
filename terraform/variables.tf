variable "subscription_id" {}
variable "client_id" {}
variable "tenant_id" {}

variable "location" {
  default = "westeurope"
}

variable "prefix" {
  default = "flaskapp"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "db_admin" {}
variable "db_password" {}

variable "docker_image" {
  description = "Docker image for the App Service"
}

variable "mysql_version" {
  default = "8.0.21"
}
