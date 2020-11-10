/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_windows_virtual_machine" "windows_host" {
  depends_on = [var.windows_host_vm_depends_on]

  # Create for each window os workstation
  for_each = var.workstations

  name                = "windows-host-${each.value.index}"
  resource_group_name = var.resource_group_name
  location            = each.value.location
  admin_username      = var.admin_name
  admin_password      = var.admin_password
  size                = each.value.vm_size

  network_interface_ids = [
    var.windows_host_nic_ids[each.value.index]
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = each.value.disk_size
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
