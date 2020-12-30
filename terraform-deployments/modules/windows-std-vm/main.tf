/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  windows_std_provisioning_script = "windows-std-provisioning.ps1"
}

# Debug public ip remove if not needed
resource "azurerm_public_ip" "windows-std-nic-public-ip" {
  for_each = var.workstations

  name                = "windows-std-nic-public-ip-${each.value.index}"
  location            = each.value.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "windows-std-nic" {

  for_each = var.workstations

  name                = "windows-std-${each.value.index}-nic"
  location            = each.value.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "windows-std-${each.value.index}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.workstation_subnet_ids[index(var.workstation_subnet_locations, each.value.location)]

    # Debug public ip remove if not needed
    public_ip_address_id = azurerm_public_ip.windows-std-nic-public-ip[each.key].id
  }
}

resource "azurerm_windows_virtual_machine" "windows-std-vm" {

  for_each = var.workstations

  name                = "${each.value.prefix}-swin-${each.value.index}"
  resource_group_name = var.resource_group_name
  location            = each.value.location
  admin_username      = var.admin_name
  admin_password      = var.admin_password
  size                = each.value.vm_size

  network_interface_ids = [
    azurerm_network_interface.windows-std-nic[each.key].id
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

resource "null_resource" "az-windows-host-configure-download" {

  depends_on = [azurerm_windows_virtual_machine.windows-std-vm]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${each.value.prefix}-swin-${each.value.index} -g ${var.resource_group_name} --scripts \"mkdir -p ${local.deploy_temp_dir};Invoke-WebRequest -UseBasicParsing ${local.deploy_script_file} -OutFile ${local.deploy_temp_dir}/${local.pcoip_agent_deploy_script} -Verbose\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-windows-host-configure-run-deploy" {

  depends_on = [null_resource.az-windows-host-configure-download]

  for_each = var.workstations

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${each.value.prefix}-swin-${each.value.index} -g ${var.resource_group_name} --scripts \"${local.deploy_temp_dir}/${local.pcoip_agent_deploy_script} ${local.pcoip_agent_deploy_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}
