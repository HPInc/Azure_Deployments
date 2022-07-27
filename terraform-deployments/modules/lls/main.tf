/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  lls_provisioning_script = "lls-provisioning.sh"
  lls_admin_password      = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_subnet" "lls" {
  # depends_on = [var.dc_network_depends_on]

  name                 = var.lls_subnet_name
  address_prefixes     = ["10.0.2.0/24"]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_name
}

resource "azurerm_network_interface" "lls-nic" {

  #   for_each = var.instance_count

  name                = "${var.host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    # name                          = "lls-${each.value.index}-ipconfig"
    name                          = "lls-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.lls.id

    # Debug public ip remove if not needed
    # public_ip_address_id = azurerm_public_ip.lls-nic-public-ip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "lls-vm" {

  #   for_each = var.instance_count

  name                            = var.host_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  admin_username                  = var.ad_service_account_username
  admin_password                  = local.lls_admin_password
  disable_password_authentication = false
  size                            = var.machine_type[0]

  network_interface_ids = [
    # azurerm_network_interface.lls-nic[each.key].id
    azurerm_network_interface.lls-nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_8"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "lls-provisioning" {

  # TODO
  depends_on = [azurerm_linux_virtual_machine.lls-vm]

  name                 = azurerm_linux_virtual_machine.lls-vm.name
  virtual_machine_id   = azurerm_linux_virtual_machine.lls-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<SETTINGS
  {
  "script": "${base64encode(templatefile("${path.module}/${local.lls_provisioning_script}.tmpl", {
  teradici_download_token = var.teradici_download_token,
  lls_admin_password      = var.lls_admin_password,
  lls_activation_code     = var.lls_activation_code,
  lls_license_count       = var.lls_license_count,
  application_id          = var.application_id
  aad_client_secret       = var.aad_client_secret
  tenant_id               = var.tenant_id
})
)
}"
    }
  SETTINGS
}
