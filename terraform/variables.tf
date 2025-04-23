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

variable "image_name" {
  description = "The Docker image name"
  type        = string
}

variable "image_tag" {
  description = "The Docker image tag"
  type        = string
  default     = "latest"
}