/*
 * Copyright (c) 2019 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

terraform {
  required_version = ">= 0.13.5"
}

provider "azurerm" {
  partner_id    = "0d95c7be-a922-5be2-841a-5381655bf4f1"
  client_id     = var.application_id
  client_secret = var.aad_client_secret
  features {}
}
