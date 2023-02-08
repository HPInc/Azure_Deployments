/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.30.0"
    }
  }
}

provider "azurerm" {
  partner_id    = "0d95c7be-a922-5be2-841a-5381655bf4f1"
  features {}
}
