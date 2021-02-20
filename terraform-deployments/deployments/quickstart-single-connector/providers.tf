terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  partner_id    = "0d95c7be-a922-5be2-841a-5381655bf4f1"
  features {}
}
