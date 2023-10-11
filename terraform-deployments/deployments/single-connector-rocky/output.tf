/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "domain-controller-private-ip" {
  value = module.dc-cac-network.dc-private-ip
}

output "domain-controller-public-ip" {
  value = module.dc-cac-network.dc-public-ip
}

output "windows-std-internal-ip" {
  value = {
    for i in range(length(module.workstation-map.windows-std-workstations)) :
    module.windows-std-vm.windows-std-vm-names[i] => module.windows-std-vm.windows-std-vm-private-ips[i]
  }
}

output "windows-gfx-internal-ip" {
  value = {
    for i in range(length(module.workstation-map.windows-gfx-workstations)) :
    module.windows-gfx-vm.windows-gfx-vm-names[i] => module.windows-gfx-vm.windows-gfx-vm-private-ips[i]
  }
}

output "centos-gfx-internal-ip" {
  value = {
    for i in range(length(module.workstation-map.centos-gfx-workstations)) :
    module.centos-gfx-vm.centos-gfx-vm-names[i] => module.centos-gfx-vm.centos-gfx-vm-private-ips[i]
  }
}

output "centos-std-internal-ip" {
  value = {
    for i in range(length(module.workstation-map.centos-std-workstations)) :
    module.centos-std-vm.centos-std-vm-names[i] => module.centos-std-vm.centos-std-vm-private-ips[i]
  }
}

output "cac-vm" {
  description = "Cac virtual machines"
  value = [for index, item in module.cac-vm.cac-vm-locations :
    {
      name : module.cac-vm.cac-vm-names[index],
      public_ip : module.cac-vm.cac-vm-public-ips[index],
      private_ip : module.cac-vm.cac-vm-private-ips[index]
    }
  ]
}
