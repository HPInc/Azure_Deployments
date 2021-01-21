/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}
