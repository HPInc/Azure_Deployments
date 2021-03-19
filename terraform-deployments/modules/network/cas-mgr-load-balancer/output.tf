/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "public-ip" {
  description = "Load balancer IP addresses"
  value       = azurerm_public_ip.loadbalancer_public_ip.*.ip_address
}
