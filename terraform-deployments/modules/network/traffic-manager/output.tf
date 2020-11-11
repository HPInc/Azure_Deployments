/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "traffic-manager-id" {
     description = "The id of the created traffic manager"
     value       = azurerm_traffic_manager_profile.main.id
}