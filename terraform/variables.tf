variable "resource_group_name" {
  default = "myapp-rg"
}

variable "location" {
  default = "westeurope"
}

variable "mysql_server_name" {
  default = "myappmysqlsrv"
}

variable "mysql_admin" {
  default = "mysqladmin"
}

variable "mysql_password" {
  default = "P@ssword1234!"
}

variable "mysql_db_name" {
  default = "appdb"
}

variable "acr_name" {
  default = "myappacr12345"
}

variable "app_name" {
  default = "myapp-service"
}