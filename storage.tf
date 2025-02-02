resource "azurerm_storage_account" "backup" {
  name                            = "${var.prefix}dbattastorage"
  resource_group_name             = azurerm_resource_group.demo.name
  location                        = azurerm_resource_group.demo.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true
  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "backup" {
  name                  = "mongodb-backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "blob"

  depends_on = [azurerm_storage_account.backup]
}