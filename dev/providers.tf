terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "management"
    storage_account_name = "finopaydemosa"
    container_name       = "state-files"
    key                  = "dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
