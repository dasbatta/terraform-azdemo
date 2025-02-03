provider "azurerm" {
  features {}
  subscription_id = getenv("AZURE_SUBSCRIPTION_ID")
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