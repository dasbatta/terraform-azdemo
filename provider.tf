terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.115.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "2b722037-a478-44f5-bfb9-6610baf35aeb"
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