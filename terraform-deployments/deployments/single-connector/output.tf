/*
 * Copyright (c) 2020 Teradici Corporation
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

output "locations" {
  value = module.dc-cac-network.subnet-workstation-locations
}

output "windows-standard-workstations" {
  value = [for index, item in module.workstation-map.windows-std-workstations :
    {
      name : module.windows-std-vm.windows-std-vm-names[item.index],
      public_ip : module.windows-std-vm.windows-std-vm-public-ips[item.index],
      private_ip : module.windows-std-vm.windows-std-vm-private-ips[item.index]
    }
  ]
}

output "centos-graphics-workstations" {
  value = [for index, item in module.workstation-map.centos-gfx-workstations :
    {
      name : module.centos-gfx-vm.centos-gfx-vm-names[item.index],
      public_ip : module.centos-gfx-vm.centos-gfx-vm-public-ips[item.index],
      private_ip : module.centos-gfx-vm.centos-gfx-vm-private-ips[item.index]
    }
  ]
}

output "centos-standard-workstations" {
  value = [for index, item in module.workstation-map.centos-std-workstations :
    {
      name : module.centos-std-vm.centos-std-vm-names[item.index],
      public_ip : module.centos-std-vm.centos-std-vm-public-ips[item.index],
      private_ip : module.centos-std-vm.centos-std-vm-private-ips[item.index]
    }
  ]
}

output "cac-vms" {
  description = "Cac virtual machines"
  value = [for index, item in module.cac-vm.cac-vm-locations :
    {
      name : module.cac-vm.cac-vm-names[index],
      public_ip : module.cac-vm.cac-vm-public-ips[index],
      private_ip : module.cac-vm.cac-vm-private-ips[index]
    }
  ]
}
