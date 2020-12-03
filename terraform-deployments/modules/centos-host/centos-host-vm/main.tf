/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_linux_virtual_machine" "centos_host" {
  depends_on = [var.centos_host_vm_depends_on]

  # Create for each window os workstation
  for_each = var.workstations

  name                            = "centos-host-${each.value.index}"
  resource_group_name             = var.resource_group_name
  location                        = each.value.location
  admin_username                  = var.admin_name
  admin_password                  = var.admin_password
  disable_password_authentication = false
  size                            = each.value.vm_size

  network_interface_ids = [
    var.centos_host_nic_ids[each.value.index]
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = each.value.disk_size
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_8"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "centos_utility_startup" {

  depends_on = [azurerm_linux_virtual_machine.centos_host]

  for_each             = var.workstations
  name                 = "centos-host-${each.value.index}"
  virtual_machine_id   = azurerm_linux_virtual_machine.centos_host[each.key].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "script": "${base64encode(file("${path.module}/centos-utility.sh"))}"
    }
  SETTINGS 
}