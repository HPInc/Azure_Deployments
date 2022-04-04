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
}

resource "time_offset" "start" {
  offset_minutes = 27
}

resource "time_offset" "expiry" {
  offset_minutes = 35
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault" "casm_keyvault" {
  name                        = var.key_vault_name == "" ? "kv-${var.resource_group_name}" : var.key_vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id
    application_id = var.application_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]

    storage_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
      "Update"
    ]
  }
}


data "azurerm_storage_account_blob_container_sas" "token" {
  depends_on = [var.blob_depends_on]
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
  depends_on = [var.casm_subnet_depends_on]
  name                 = "${var.cas_mgr_subnet_name}-${var.resource_group_name}"
  address_prefixes     = var.cas_mgr_subnet_cidr
  resource_group_name  = var.aadds_resource_group == "" ? var.resource_group_name : var.aadds_resource_group
  virtual_network_name = var.azurerm_virtual_network_name
}

resource "azurerm_subnet_network_security_group_association" "cas" {
  subnet_id                 = azurerm_subnet.cas-mgr.id
  network_security_group_id = var.network_security_group_ids[0]
}

resource "azurerm_network_interface" "cas-mgr-nic" {
  name                = "${var.host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "cas-mgr-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.cas-mgr.id
  }
}

resource "azurerm_storage_blob" "cas-mgr-setup-script" {
  depends_on = [var.casm_depends_on, var.blob_depends_on]
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
  size                            = var.machine_type

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
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_3"
    version   = "latest"
  }
}

resource "null_resource" "upload-casm-config" {

  depends_on = [
    azurerm_linux_virtual_machine.cas-mgr-vm,
    azurerm_network_interface_nat_rule_association.cas_association_ssh
  ]

  connection {
    type     = "ssh"
    user     = var.ad_service_account_username
    password = local.cas_mgr_admin_password
    host     = var.cas_mgr_public_ip.ip_address
    port     = "22"
  }

  provisioner "file" {
    source = "${path.module}/mongodb-org-4.4.repo"
    destination = "/home/${var.ad_service_account_username}/mongodb-org-4.4.repo"
  }

  provisioner "file" {
    content = templatefile("${path.module}/mongod.conf.tmpl", {
      vm_private_ip = azurerm_network_interface.cas-mgr-nic.private_ip_address,
    })
    destination = "/home/${var.ad_service_account_username}/mongod.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/casm.conf.tmpl", {
      vm_private_ip = azurerm_network_interface.cas-mgr-nic.private_ip_address,
      azure_client_id = var.application_id,
      azure_client_secret = var.aad_client_secret,
      azure_tenant_id = var.tenant_id,
      key_vault_url = azurerm_key_vault.casm_keyvault.vault_uri,
      db_username = var.db_username,
      db_password = var.db_password
    })
    destination = "/home/${var.ad_service_account_username}/casm.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/dbconf.mongo.tmpl", {
      vm_private_ip = azurerm_network_interface.cas-mgr-nic.private_ip_address,
      db_username = var.db_username,
      db_password = var.db_password
    })
    destination = "/home/${var.ad_service_account_username}/dbconf.mongo"
  }
}

resource "azurerm_virtual_machine_extension" "cas-mgr-provisioning" {

  depends_on = [azurerm_linux_virtual_machine.cas-mgr-vm, azurerm_storage_blob.cas-mgr-setup-script, null_resource.upload-casm-config, azurerm_lb_outbound_rule.cas_outbound]

  name                 = azurerm_linux_virtual_machine.cas-mgr-vm.name
  virtual_machine_id   = azurerm_linux_virtual_machine.cas-mgr-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<SETTINGS
  {
  "script": "${base64encode(templatefile("${path.module}/${local.cas_mgr_provisioning_script}.tmpl", {
  cas_mgr_username           = var.ad_service_account_username
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
  tenant_id                  = local.tenant_id
})
)
}"
    }
  SETTINGS
}

resource "azurerm_lb_backend_address_pool" "cas-mgr" {
  depends_on = [var.cas_nat_depends_on, azurerm_linux_virtual_machine.cas-mgr-vm]
  loadbalancer_id = var.lb_id
  name            = "cas-mgr-pool"
}

# Optional load balancer vm association
resource "azurerm_network_interface_backend_address_pool_association" "cas-association" {
  depends_on = [var.cas_nat_depends_on, azurerm_linux_virtual_machine.cas-mgr-vm]
  network_interface_id    = azurerm_network_interface.cas-mgr-nic.id
  ip_configuration_name   = "cas-mgr-ipconfig"
  backend_address_pool_id = azurerm_lb_backend_address_pool.cas-mgr.id
}

resource "azurerm_lb_outbound_rule" "cas_outbound" {
  depends_on = [azurerm_network_interface_backend_address_pool_association.cas-association]
  loadbalancer_id         = var.lb_id
  name                    = "cas-outbound"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.cas-mgr.id

  frontend_ip_configuration {
    name = "ip-config-cas-frontend"
  }
}

resource "azurerm_lb_nat_rule" "cas_nat" {
  depends_on = [var.cas_nat_depends_on,azurerm_lb_outbound_rule.cas_outbound]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "ip-config-cas-frontend"
}

resource "azurerm_network_interface_nat_rule_association" "cas_association" {
  network_interface_id  = azurerm_network_interface.cas-mgr-nic.id
  ip_configuration_name = "cas-mgr-ipconfig"
  nat_rule_id           = azurerm_lb_nat_rule.cas_nat.id
}

resource "azurerm_lb_nat_rule" "cas_nat_ssh" {
  depends_on = [azurerm_network_interface_nat_rule_association.cas_association, azurerm_lb_nat_rule.cas_nat, azurerm_linux_virtual_machine.cas-mgr-vm]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "ip-config-cas-frontend"
}

resource "azurerm_network_interface_nat_rule_association" "cas_association_ssh" {
  depends_on = [azurerm_network_interface_nat_rule_association.cas_association, azurerm_lb_nat_rule.cas_nat_ssh, azurerm_linux_virtual_machine.cas-mgr-vm]
  network_interface_id  = azurerm_network_interface.cas-mgr-nic.id
  ip_configuration_name = "cas-mgr-ipconfig"
  nat_rule_id           = azurerm_lb_nat_rule.cas_nat_ssh.id
}
