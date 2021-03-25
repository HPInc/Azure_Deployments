/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "public-ip" {
  value = module.cac-regional[*].cac-public-ip
}

output "network-interface-nic-ids" {
  value = module.cac-regional[*].network-interface-ids
}

output "vm-names" {
  value = module.cac-regional[*].cac-vm-names
}
