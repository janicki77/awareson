provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg-${var.env}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet-${var.env}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "${var.prefix}-mysql-${var.env}"
  location               = var.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.db_admin
  administrator_password = var.db_password
  sku_name               = "GP_Standard_D2ds_v4"
  version                = var.mysql_version
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  zone                   = "1"
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_link" {
  name                  = "mysql-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "mysql_pe" {
  name                = "${var.prefix}-mysql-pe-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.db_subnet.id

  private_service_connection {
    name                           = "mysql-priv-conn"
    private_connection_resource_id = azurerm_mysql_flexible_server.mysql.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-plan-${var.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_app_service" "app" {
  name                = "${var.prefix}-app-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|${var.docker_image}"
  }

  app_settings = {
    WEBSITES_PORT     = "5000"
    DB_HOST           = azurerm_mysql_flexible_server.mysql.fqdn
    DB_USER           = "${var.db_admin}@${azurerm_mysql_flexible_server.mysql.name}"
    DB_PASSWORD       = var.db_password
    DB_NAME           = "flaskdb"
  }
}
