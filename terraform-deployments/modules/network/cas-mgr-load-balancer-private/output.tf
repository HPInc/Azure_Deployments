/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "private-ip" {
  description = "Load balancer IP address"
  value       = azurerm_lb.main.private_ip_address
}
