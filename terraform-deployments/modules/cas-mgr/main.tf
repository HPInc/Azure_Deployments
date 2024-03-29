/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  cas_mgr_admin_password      = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
  cas_mgr_provisioning_script = "cas-mgr-provisioning.sh"
  cas_mgr_setup_script        = "cas-mgr-setup.py"
  tenant_id                   = var.key_vault_id == "" ? "" : var.tenant_id
  default_tags               = {
    "${var.tag_name}" = "${var.tag_prefix} ${var.tag_value} ${var.tag_suffix}"
  }
}

resource "time_offset" "start" {
  offset_days = -1
}

resource "time_offset" "expiry" {
  offset_days = 1
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

data "azurerm_storage_account_blob_container_sas" "token" {
  connection_string = var.storage_connection_string
  container_name    = var.private_container_name
  https_only        = true

  start  = time_offset.start.rfc3339
  expiry = time_offset.expiry.rfc3339

  # TODO: fix IP address whitelist.
  # ip_address = azurerm_public_ip.cas-mgr-public-ip.ip_address

  permissions {
    read   = false
    add    = false
    create = false
    write  = true
    delete = false
    list   = false
  }
}

resource "azurerm_subnet" "cas-mgr" {
  depends_on           = [var.cas_mgr_subnet_depends_on]
  name                 = var.cas_mgr_subnet_name
  address_prefixes     = var.cas_mgr_subnet_cidr
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_name
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  subnet_id                 = azurerm_subnet.cas-mgr.id
  network_security_group_id = var.network_security_group_ids[0]
}

resource "azurerm_public_ip" "cas-mgr-public-ip" {
  name                = "cas-mgr-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "cas-mgr-nic" {
  name                = "${var.host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "cas-mgr-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.cas-mgr.id
    public_ip_address_id          = azurerm_public_ip.cas-mgr-public-ip.id
  }

  tags     = "${local.default_tags}"
}

resource "azurerm_storage_blob" "cas-mgr-setup-script" {
  depends_on = [
    var.blob_depends_on
  ]
  name                   = local.cas_mgr_setup_script
  storage_account_name   = var.storage_account_name
  storage_container_name = var.storage_account_name
  type                   = "Block"
  source                 = "${path.module}/${local.cas_mgr_setup_script}"
}

resource "azurerm_linux_virtual_machine" "cas-mgr-vm" {
  name                            = var.host_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  admin_username                  = var.ad_service_account_username
  admin_password                  = local.cas_mgr_admin_password
  disable_password_authentication = false
  size                            = var.machine_type[0]

  network_interface_ids = [
    azurerm_network_interface.cas-mgr-nic.id
  ]

  os_disk {
    name                 = "cas-mgr-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513" 
    offer = "rockylinux" 
    sku = "free" 
    version = "latest" 
  }

  plan { 
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513" 
    product = "rockylinux" 
    name = "free" 
  } 

  tags     = "${local.default_tags}"
}

resource "null_resource" "upload-provisioning-script" {

  depends_on = [
    azurerm_linux_virtual_machine.cas-mgr-vm
  ]

  connection {
    type     = "ssh"
    user     = var.ad_service_account_username
    password = local.cas_mgr_admin_password
    host     = azurerm_public_ip.cas-mgr-public-ip.ip_address
    port     = "22"
  }

  provisioner "file" {
    content = templatefile("${path.module}/${local.cas_mgr_provisioning_script}.tmpl", {
      cas_mgr_add_repo_script    = var.cas_mgr_add_repo_script,
      cas_mgr_deployment_sa_file = var.cas_mgr_deployment_sa_file,
      cas_mgr_admin_password     = var.cas_mgr_admin_password,
      cas_mgr_setup_script       = local.cas_mgr_setup_script,
      cas_mgr_setup_script_url   = azurerm_storage_blob.cas-mgr-setup-script.url,
      sas_token                  = data.azurerm_storage_account_blob_container_sas.token.sas,
      private_container_url      = var.private_container_url,
      pcoip_registration_code    = var.pcoip_registration_code,
      application_id             = var.application_id,
      aad_client_secret          = var.aad_client_secret,
      tenant_id                  = var.tenant_id
    })
    destination = "/home/${var.ad_service_account_username}/cas-mgr-provisioning.sh"
  }
}

resource "null_resource" "run-cac-provisioning-script" {

  depends_on = [
    null_resource.upload-provisioning-script
  ]

  connection {
    type     = "ssh"
    user     = var.ad_service_account_username
    password = local.cas_mgr_admin_password
    host     = azurerm_public_ip.cas-mgr-public-ip.ip_address
    port     = "22"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf -y -q update",
      "sudo dnf check -v",
      "sudo dnf install -y dos2unix",
      "if [ $? -eq 1 ]; then sudo dnf check -v; sudo dnf install -y dos2unix; fi",
      "sudo dos2unix ${local.cas_mgr_provisioning_script}",
      "sudo bash ${local.cas_mgr_provisioning_script}",
    ]
  }
}