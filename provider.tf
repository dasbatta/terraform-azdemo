provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    config_path = "kube-config"
  }
}

provider "tls" {
}

provider "local" {
}

provider "random" {
}

provider "null" {
}