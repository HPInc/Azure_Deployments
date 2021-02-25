/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "traffic-manager-fqdn" {
  description = "The FQDN of the traffic manager"
  value       = azurerm_traffic_manager_profile.main.fqdn
}
