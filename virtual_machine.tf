data "azurerm_subscription" "primary" {}

resource "tls_private_key" "demo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "mongodb_password" {
  length  = 16
  special = false
}

# Create the cronjob script
locals {
  backup_script = templatefile("${path.module}/cronjob.sh.tpl", {
    storage_account_name = azurerm_storage_account.backup.name
    container_name       = azurerm_storage_container.backup.name
    mongo_password       = random_password.mongodb_password.result
  })
}

# Create the mongodb set up script
locals {
  mongodb_script = templatefile("${path.module}/setup_mongodb.sh.tpl", {
    mongo_password = random_password.mongodb_password.result
  })
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "demo" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = "Standard_DS2_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.demo.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "18.04.201908220"
  }

  # Copy script and install the previous major mongodb version
  provisioner "file" {
    content     = local.mongodb_script
    destination = "/tmp/setup_mongodb.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = "azureuser"
      private_key = file(local_file.private_key.filename)
    }
  }
  # Copy the cronjob to create mongodb backups
  provisioner "file" {
    content     = local.backup_script
    destination = "/tmp/cronjob.sh"
    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = "azureuser"
      private_key = file(local_file.private_key.filename)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_mongodb.sh",
      "/tmp/setup_mongodb.sh",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "mkdir -p mongo-backups",
      "chmod +x /tmp/cronjob.sh",
      "mkdir /tmp/log",
      "crontab -l | { cat; echo '*/5 * * * * /tmp/cronjob.sh >> /tmp/log/backup.log 2>&1'; } | crontab -",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip_address
      user        = "azureuser"
      private_key = file(local_file.private_key.filename)
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

# Assing owner (elevated) role to the managed identity associated with the virtual machine
resource "azurerm_role_assignment" "vm_role_assignment" {
  principal_id         = azurerm_linux_virtual_machine.demo.identity[0].principal_id
  role_definition_name = "Owner"
  scope                = "/subscriptions/${data.azurerm_subscription.primary.subscription_id}"
}

# Authenticate so the VM can use the managed identity permissions 
resource "null_resource" "post_provisioning" {
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "az login --identity --username ${azurerm_linux_virtual_machine.demo.identity[0].principal_id}",
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.demo.public_ip_address
      user        = "azureuser"
      private_key = file(local_file.private_key.filename)
    }
  }

  depends_on = [
    azurerm_linux_virtual_machine.demo,
    azurerm_role_assignment.vm_role_assignment
  ]
}

resource "local_file" "private_key" {
  content         = tls_private_key.demo.private_key_pem
  filename        = "demo_key.pem"
  file_permission = "0600"
}