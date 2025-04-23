provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    use_azuread_auth = true
    storage_account_name = "tfstateawareson123"
    container_name = "tfstate"
    key = "dev.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-dev"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "mysql_delegated" {
  name                 = "mysql-delegated-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "mysql_pe" {
  name                 = "mysql-pe-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_mysql_flexible_server" "main" {
  name                   = var.mysql_server_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.location
  administrator_login    = var.mysql_admin
  administrator_password = var.mysql_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  delegated_subnet_id    = azurerm_subnet.mysql_delegated.id
  private_dns_zone_id    = null
}

resource "azurerm_mysql_flexible_database" "db" {
  name                = var.mysql_db_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "azurerm_private_endpoint" "mysql" {
  name                = "mysql-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.mysql_pe.id

  private_service_connection {
    name                           = "mysql-connection"
    private_connection_resource_id = azurerm_mysql_flexible_server.main.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_app_service_plan" "main" {
  name                = "asp-dev"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "main" {
  name                = var.app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/flask-app:latest"
  }

  app_settings = {
    MYSQL_HOST     = azurerm_mysql_flexible_server.main.fqdn
    MYSQL_USER     = var.mysql_admin
    MYSQL_PASSWORD = var.mysql_password
    MYSQL_DB       = var.mysql_db_name
    WEBSITES_PORT  = 5000
  }

  depends_on = [ azurerm_container_registry.acr, azurerm_mysql_flexible_database.db ]
}