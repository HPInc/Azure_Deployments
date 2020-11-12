/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "domain-controller-group" {
  value = azurerm_resource_group.main.name
}

output "domain-controller-private-ip" {
  value = module.dc-cac-network.dc-private-ip
}

output "domain-controller-public-ip" {
  value = module.dc-cac-network.dc-public-ip
}

output "windows-workstations" {
  value = [for index, item in module.workstation-map.windows-workstations: 
    {
      location: item.location,
      name: module.windows-host-vm.windows-host-vm-names[item.index],
      id: module.windows-host-vm.windows-host-vm-ids[item.index],
      size: module.windows-host-vm.windows-host-vm-size[item.index],
      public_ip: module.windows-host-vm.windows-host-vm-public-ips[item.index],
      private_ip: module.windows-host-vm.windows-host-vm-private-ips[item.index]
    }
  ]
}

output "linux-workstations" {
  value = [for index, item in module.workstation-map.linux-workstations: 
    {
      location: item.location,
      name: module.centos-host-vm.centos-host-vm-names[item.index],
      id: module.centos-host-vm.centos-host-vm-ids[item.index]
      size: module.centos-host-vm.centos-host-vm-size[item.index],
      public_ip: module.centos-host-vm.centos-host-vm-public-ips[item.index],
      private_ip: module.centos-host-vm.centos-host-vm-private-ips[item.index]
    }
  ]
}

output "cac-vms" {
  description = "Cac virtual machines"
  value = [for index, item in module.cac-vm.cac-vm-locations: 
    {
      location: item,
      name: module.cac-vm.cac-vm-names[index],
      id: module.cac-vm.cac-vm-ids[index],
      size: module.cac-vm.cac-vm-size[index],
      public_ip: module.cac-vm.cac-vm-public-ips[index],
      private_ip: module.cac-vm.cac-vm-private-ips[index]
    }
  ]
}