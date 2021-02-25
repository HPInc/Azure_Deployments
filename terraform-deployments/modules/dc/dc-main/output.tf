/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "domain-controller-private-ip" {
  value = module.active-directory-domain-network.private-ip
}

output "domain-controller-public-ip" {
  value = module.active-directory-domain-network.public-ip
}

output "domain-controller-vm-name" {
  value = module.active-directory-domain-vm.domain-controller-name
}