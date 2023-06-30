resource "azurerm_storage_account" "sairaj-storage" {
  name                     = "sairajstorage1"
  resource_group_name      = azurerm_resource_group.sairaj-rg.name
  location                 = azurerm_resource_group.sairaj-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "sairaj-container" {
  name                  = "sairaj-container"
  storage_account_name  = azurerm_storage_account.sairaj-storage.name
  container_access_type = "private"
}