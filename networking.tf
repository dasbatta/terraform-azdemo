resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-vm-pip"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  allocation_method   = "Static"
  sku                  = "Basic"
}

resource "azurerm_virtual_network" "demo" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.prefix}-aks-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.prefix}-vm-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "demo" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                         = "allow_aks_to_vm"
    priority                     = 1000
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = ["10.0.2.0/24"] # VM subnet range
    destination_address_prefixes = ["10.0.1.0/24"] # AKS subnet range
  }

  security_rule {
    name                         = "allow_vm_to_aks"
    priority                     = 1001
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = ["10.0.1.0/24"] # AKS subnet range
    destination_address_prefixes = ["10.0.2.0/24"] # VM subnet range
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "webapp"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.public_ip_address
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.demo.id
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm_subnet.id
  network_security_group_id = azurerm_network_security_group.demo.id
}
