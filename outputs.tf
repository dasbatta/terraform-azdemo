output "get_credentials_command" {
  description = "Command to access the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.demo.name} --name ${azurerm_kubernetes_cluster.demo.name}"
}


output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh -i demo_key.pem azureuser@${azurerm_linux_virtual_machine.demo.public_ip_address}"
}
