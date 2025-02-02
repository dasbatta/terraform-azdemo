data "azurerm_container_registry" "existing_acr" {
  name                = "wizdemo"
  resource_group_name = "acr"
}


resource "azurerm_kubernetes_cluster" "demo" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  dns_prefix          = "${var.prefix}-dns"

  default_node_pool {
    name           = "pool1"
    node_count     = var.node_count
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    dns_service_ip = cidrhost("10.0.3.0/24", 10)
    service_cidr   = "10.0.3.0/24"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

# Allow the cluster to pull from my private ACR where the web app lives
resource "azurerm_role_assignment" "aks_role_assignment" {
  principal_id         = azurerm_kubernetes_cluster.demo.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.existing_acr.id
}

resource "local_file" "kube_config" {
  content  = azurerm_kubernetes_cluster.demo.kube_config_raw
  filename = "./kube-config"
}
