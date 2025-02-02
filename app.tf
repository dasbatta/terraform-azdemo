resource "random_password" "secret_key" {
  length  = 10
  special = false
}

resource "helm_release" "webapp" {
  name    = "webapp"
  chart   = "./helm"
  version = "1.0.0"

  set {
    name  = "secret.secretKey"
    value = random_password.secret_key.result
  }

  set {
    name  = "secret.mongodbUri"
    value = "mongodb://backupuser:${random_password.mongodb_password.result}@${azurerm_linux_virtual_machine.demo.private_ip_address}:27017"
  }

}