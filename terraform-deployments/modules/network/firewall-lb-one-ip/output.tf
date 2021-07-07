/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "fw-name" {
  value = azurerm_firewall.cac-fw.name
}

output "fw-frontend" {
  value = azurerm_public_ip.fw-frontend.ip_address
}

output "fw-internal" {
  value = azurerm_firewall.cac-fw.ip_configuration[0].private_ip_address
}

output "cac-fw-public" {
  value = azurerm_public_ip.cac.*
}

output "dc-fw-public" {
  value = azurerm_public_ip.dc_ip
}

output "cas-fw-public" {
  value = azurerm_public_ip.cas-mgr-public-ip
}