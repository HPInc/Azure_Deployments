/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

# Debug public ip remove if not needed
# resource "azurerm_public_ip" "windows-gfx-nic-public-ip" {
#   for_each = var.workstations

#   name                = "windows-gfx-nic-public-ip-${each.value.index}"
#   location            = each.value.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

resource "azurerm_network_interface" "windows-gfx-nic" {

  for_each = var.workstations

  name                = "windows-gfx-${each.value.index}-nic"
  location            = each.value.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "windows-gfx-${each.value.index}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.workstation_subnet_ids[index(var.workstation_subnet_locations, each.value.location)]

    # Debug public ip remove if not needed
    # public_ip_address_id = azurerm_public_ip.windows-gfx-nic-public-ip[each.key].id
  }
}

resource "azurerm_storage_blob" "windows-gfx-script" {
  depends_on = [
    var.blob_depends_on
  ]
  name                   = local.windows_gfx_provisioning_script
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_account_name
  type                   = "Block"
  source                 = "${path.module}/${local.windows_gfx_provisioning_script}"
}

resource "azurerm_windows_virtual_machine" "windows-gfx-vm" {
  for_each = var.workstations

  name                = each.value.prefix == "" ? "gwin-${each.value.index}" : "${each.value.prefix}-gwin-${each.value.index}"
  resource_group_name = var.resource_group_name
  location            = each.value.location
  admin_username      = var.admin_name
  admin_password      = local.windows_admin_password
  size                = each.value.vm_size

  network_interface_ids = [
    azurerm_network_interface.windows-gfx-nic[each.key].id
  ]

  os_disk {
    name                 = each.value.prefix == "" ? "gwin-vm-osdisk-${each.value.index}" : "${each.value.prefix}-gwin-vm-osdisk-${each.value.index}"
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

resource "null_resource" "windows-gfx-script-download" {

  depends_on = [azurerm_windows_virtual_machine.windows-gfx-vm]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.windows-gfx-vm[each.key].name} -g ${var.resource_group_name} --scripts \"mkdir -p ${local.deploy_temp_dir};Invoke-WebRequest -UseBasicParsing ${azurerm_storage_blob.windows-gfx-script.url} -OutFile ${local.deploy_temp_dir}/${local.windows_gfx_provisioning_script} -Verbose\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "windows-gfx-driver-installation" {

  depends_on = [null_resource.windows-gfx-script-download]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.windows-gfx-vm[each.key].name} -g ${var.resource_group_name} --scripts \"${local.deploy_temp_dir}/${local.windows_gfx_provisioning_script} ${local.windows_gfx_provisioning_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "windows-gfx-pcoip-installation" {

  depends_on = [null_resource.windows-gfx-driver-installation]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.windows-gfx-vm[each.key].name} -g ${var.resource_group_name} --scripts \"${local.deploy_temp_dir}/${local.windows_gfx_provisioning_script} ${local.windows_gfx_provisioning_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "windows-gfx-restart" {

  depends_on = [null_resource.windows-gfx-pcoip-installation]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.windows-gfx-vm[each.key].name} -g ${var.resource_group_name} --scripts \"${local.deploy_temp_dir}/${local.windows_gfx_provisioning_script} ${local.windows_gfx_provisioning_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}
