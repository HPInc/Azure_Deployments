/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  centos_gfx_provisioning_script = "centos-gfx-provisioning.sh"
  ad_admin_password              = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].id)
  centos_admin_password          = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

# Debug public ip remove if not needed
# resource "azurerm_public_ip" "centos-gfx-nic-public-ip" {

#   for_each = var.workstations

#   name                = "centos-gfx-nic-public-ip-${each.value.index}"
#   location            = each.value.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

resource "azurerm_network_interface" "centos-gfx-nic" {

  for_each = var.workstations

  name                = "centos-gfx-${each.value.index}-nic"
  location            = each.value.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "centos-gfx-${each.value.index}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.workstation_subnet_ids[index(var.workstation_subnet_locations, each.value.location)]

    # Debug public ip remove if not needed
    # public_ip_address_id = azurerm_public_ip.centos-gfx-nic-public-ip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "centos-gfx-vm" {

  for_each = var.workstations

  name                            = each.value.prefix == "" ? "gcent-${each.value.index}" : "${each.value.prefix}-gcent-${each.value.index}"
  resource_group_name             = var.resource_group_name
  location                        = each.value.location
  admin_username                  = var.admin_name
  admin_password                  = local.centos_admin_password
  disable_password_authentication = false
  size                            = each.value.vm_size

  network_interface_ids = [
    azurerm_network_interface.centos-gfx-nic[each.key].id
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

resource "azurerm_virtual_machine_extension" "centos-gfx-provisioning" {

  depends_on = [azurerm_linux_virtual_machine.centos-gfx-vm]

  for_each             = var.workstations
  name                 = each.value.prefix == "" ? "gcent-${each.value.index}" : "${each.value.prefix}-gcent-${each.value.index}"
  virtual_machine_id   = azurerm_linux_virtual_machine.centos-gfx-vm[each.key].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<SETTINGS
  {
  "script": "${base64encode(templatefile("${path.module}/${local.centos_gfx_provisioning_script}.tmpl", {
  pcoip_registration_code     = var.pcoip_registration_code,
  ad_service_account_password = local.ad_admin_password,
  ad_service_account_username = var.ad_service_account_username,
  domain_name                 = var.domain_name,
  domain_controller_ip        = var.domain_controller_ip,
  application_id              = var.application_id,
  aad_client_secret           = var.aad_client_secret,
  tenant_id                   = var.tenant_id,
  app_id                      = var.application_id,
  nvidia_driver_url           = var.nvidia_driver_url
})
)
}"
  }
  SETTINGS
}

