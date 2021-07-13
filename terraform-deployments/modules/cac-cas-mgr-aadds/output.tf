/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "public-ip" {
  value = var.is_private == false ? module.cac-regional[*].cac-public-ip : var.cac_fw_public[*].ip_address 
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

output "cac-nat-rules" {
  value = var.is_private == false ? null : module.cac-regional-private[0].cac-nat-rules
}

output "cac-fw-rules" {
  value = var.is_private == false ? null : module.cac-regional-private[0].cac-fw-rules
}