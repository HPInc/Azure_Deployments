/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

# Debug public ip remove if not needed
# resource "azurerm_public_ip" "windows-std-nic-public-ip" {

resource "azurerm_public_ip" "windows-std-nic-public-ip" {
  name                = "aadds-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "windows-std-nic" {
  name                = "windows-std-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "windows-std-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.workstation_subnet_ids[0]
    public_ip_address_id = azurerm_public_ip.windows-std-nic-public-ip.id
  }
}

resource "azurerm_windows_virtual_machine" "aadds-mgmt-vm" {
  name                = "aadds-mgmt"
  resource_group_name = var.resource_group_name
  location            = var.location
  admin_username      = var.admin_name
  admin_password      = local.windows_admin_password
  size                = "Standard_F2"

  network_interface_ids = [
    azurerm_network_interface.windows-std-nic.id
  ]

  os_disk {
    name                 = "mgmt-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_storage_blob" "windows-std-script" {
  depends_on = [
    var.blob_depends_on
  ]
  name                   = local.windows_std_provisioning_script
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_account_name
  type                   = "Block"
  source                 = "${path.module}/${local.windows_std_provisioning_script}"
}

resource "null_resource" "az-windows-host-configure-download" {

  depends_on = [azurerm_windows_virtual_machine.aadds-mgmt-vm]

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.aadds-mgmt-vm.name} -g ${var.resource_group_name} --scripts \"mkdir -p ${local.deploy_temp_dir};Invoke-WebRequest -UseBasicParsing ${azurerm_storage_blob.windows-std-script.url} -OutFile ${local.deploy_temp_dir}/${local.windows_std_provisioning_script} -Verbose\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-windows-host-configure-run-deploy" {

  depends_on = [null_resource.az-windows-host-configure-download]

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name ${azurerm_windows_virtual_machine.aadds-mgmt-vm.name} -g ${var.resource_group_name} --scripts \"${local.deploy_temp_dir}/${local.windows_std_provisioning_script} ${local.windows_std_provisioning_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}
