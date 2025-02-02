resource "azurerm_resource_group" "demo" {
  name     = "${var.prefix}-rg"
  location = var.location
}