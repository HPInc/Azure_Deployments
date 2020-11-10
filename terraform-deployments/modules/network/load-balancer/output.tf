/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "load-balancer-ids" {
  description = "The created load balancer ids"
  value       = [for item in azurerm_lb.main : item.id]
}
