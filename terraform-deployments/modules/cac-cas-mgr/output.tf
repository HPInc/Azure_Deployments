/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "public-ip" {
  value = var.is_private == false ? module.cac-regional[*].cac-public-ip : module.cac-regional-private[*].cac-public-ip 
}

output "network-interface-nic-ids" {
  value = var.is_private == false ? module.cac-regional[*].network-interface-ids : module.cac-regional-private[*].network-interface-ids
}

output "vm-names" {
  value = var.is_private == false ? module.cac-regional[*].cac-vm-names : module.cac-regional-private[*].cac-vm-names
}

output "subnet-ids" {
  value = var.is_private == false ? module.cac-regional[*].cac-subnet-ids : module.cac-regional-private[*].cac-subnet-ids
}

output "cac-fw-name" {
  value = module.cac-regional-private[*].cac-fw-name
}

output "cac-fw-frontend" {
  value = module.cac-regional-private[*].cac-fw-frontend
}

output "cac-fw-internal" {
  value = module.cac-regional-private[*].cac-fw-internal
}