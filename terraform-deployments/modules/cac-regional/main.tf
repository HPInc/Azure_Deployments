/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  cac_provisioning_script = "cac-provisioning.sh"
  ad_admin_password       = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].id)
  cac_admin_password      = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
  ssl_key_filename        = var.ssl_key == "" ? "" : basename(var.ssl_key)
  ssl_cert_filename       = var.ssl_cert == "" ? "" : basename(var.ssl_cert)
  prefix                  = var.prefix != "" ? "${var.prefix}-" : ""
  cas_mgr_script          = "get-cac-token.py"
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

resource "time_offset" "start" {
  offset_minutes = 0
}

resource "time_offset" "expiry" {
  offset_minutes = 32
}

data "azurerm_storage_account_blob_container_sas" "token" {

  count = var.instance_count

  connection_string = var.storage_connection_string
  container_name    = var.private_container_name
  https_only        = true

  start  = time_offset.start.rfc3339
  expiry = time_offset.expiry.rfc3339

  # TODO: fix IP address whitelist.
  # ip_address = azurerm_public_ip.cac[count.index].ip_address

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

resource "azurerm_subnet" "cac" {
  name                 = "${var.cac_subnet_name}-${var.location}"
  address_prefixes     = var.cac_subnet_cidr
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  subnet_id                 = azurerm_subnet.cac.id
  network_security_group_id = var.network_security_group_id
}


resource "azurerm_public_ip" "cac" {

  count = var.instance_count

  name                    = "public-ip-cac-${var.location}-${count.index}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  sku                     = "Standard"
}

resource "azurerm_network_interface" "cac-nic" {

  count = var.instance_count

  name                = "${local.prefix}cac-nic-${var.location}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cac[count.index].id
    subnet_id                     = azurerm_subnet.cac.id
    primary                       = "true"
  }
}

resource "azurerm_linux_virtual_machine" "cac-vm" {

  count = var.instance_count

  name                            = "${local.prefix}cac-vm-${var.location}-${count.index}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.machine_type
  admin_username                  = var.cac_admin_user
  admin_password                  = local.cac_admin_password
  computer_name                   = "${local.prefix}cac-vm"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.cac-nic[count.index].id
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${local.prefix}cac-vm-osdisk-${var.location}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "azurerm_template_deployment" "shutdown_schedule_template" {
  depends_on = [
    azurerm_linux_virtual_machine.cac-vm
  ]

  count = var.instance_count

  name                = "${azurerm_linux_virtual_machine.cac-vm[count.index].name}-shutdown-schedule-template"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  parameters = {
    "location"                       = var.location
    "virtualMachineName"             = azurerm_linux_virtual_machine.cac-vm[count.index].name
    "autoShutdownStatus"             = "Enabled"
    "autoShutdownTime"               = "18:00"
    "autoShutdownTimeZone"           = "Pacific Standard Time"
    "autoShutdownNotificationStatus" = "Disabled"
    "autoShutdownNotificationLocale" = "en"
  }

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
      "parameters": {
          "location": {
              "type": "string"
          },
          "virtualMachineName": {
              "type": "string"
          },
          "autoShutdownStatus": {
              "type": "string"
          },
          "autoShutdownTime": {
              "type": "string"
          },
          "autoShutdownTimeZone": {
              "type": "string"
          },
          "autoShutdownNotificationStatus": {
              "type": "string"
          },
          "autoShutdownNotificationLocale": {
              "type": "string"
          }
      },
      "resources": [
        {
            "name": "[concat('shutdown-computevm-', parameters('virtualMachineName'))]",
            "type": "Microsoft.DevTestLab/schedules",
            "apiVersion": "2018-09-15",
            "location": "[parameters('location')]",
            "properties": {
                "status": "[parameters('autoShutdownStatus')]",
                "taskType": "ComputeVmShutdownTask",
                "dailyRecurrence": {
                    "time": "[parameters('autoShutdownTime')]"
                },
                "timeZoneId": "[parameters('autoShutdownTimeZone')]",
                "targetResourceId": "[resourceId('Microsoft.Compute/virtualMachines', parameters('virtualMachineName'))]",
                "notificationSettings": {
                    "status": "[parameters('autoShutdownNotificationStatus')]",
                    "notificationLocale": "[parameters('autoShutdownNotificationLocale')]",
                    "timeInMinutes": "30"
                }
            }
        }
    ]
  }
  DEPLOY
}

resource "null_resource" "upload-ssl" {

  depends_on = [
    azurerm_linux_virtual_machine.cac-vm
  ]

  count = var.ssl_key == "" ? 0 : var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = azurerm_public_ip.cac[count.index].ip_address
    port     = "22"
  }

  provisioner "file" {
    source      = var.ssl_key
    destination = "/tmp/${local.ssl_key_filename}"
  }

  provisioner "file" {
    source      = var.ssl_cert
    destination = "/tmp/${local.ssl_cert_filename}"
  }
}

resource "null_resource" "upload-provisioning-script" {

  depends_on = [
    azurerm_linux_virtual_machine.cac-vm
  ]

  count = var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = azurerm_public_ip.cac[count.index].ip_address
    port     = "22"
  }

  provisioner "file" {
    content = templatefile("${path.module}/${local.cac_provisioning_script}.tmpl", {
      cac_installer_url           = var.cac_installer_url
      cas_mgr_script              = local.cas_mgr_script
      cas_mgr_deployment_sa_file  = var.cas_mgr_deployment_sa_file
      cas_mgr_setup_script_url    = var.cas_mgr_setup_script_url
      cas_mgr_insecure            = var.cas_mgr_insecure ? "true" : "",
      domain_controller_ip        = var.domain_controller_ip
      ad_service_account_username = var.ad_service_account_username
      ad_service_account_password = local.ad_admin_password
      domain_name                 = var.domain_name
      cas_mgr_url                 = var.cas_mgr_url
      ssl_key                     = local.ssl_key_filename
      ssl_cert                    = local.ssl_cert_filename
      application_id              = var.application_id
      aad_client_secret           = var.aad_client_secret
      tenant_id                   = var.tenant_id
      lls_ip                      = var.lls_ip
      external_pcoip_ip           = azurerm_public_ip.cac[count.index].ip_address,
      sas_token                   = data.azurerm_storage_account_blob_container_sas.token[count.index].sas
      private_container_url       = var.private_container_url
    })
    destination = "/home/${var.cac_admin_user}/cac-provisioning.sh"
  }
}

resource "null_resource" "run-cac-provisioning-script" {

  depends_on = [
    null_resource.upload-provisioning-script
  ]

  count = var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = azurerm_public_ip.cac[count.index].ip_address
    port     = "22"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm /var/lib/apt/lists/*",
      "sudo apt -y update",
      "sudo lsof /var/lib/dpkg/lock-frontend",
      "sudo apt install dos2unix",
      "if [ $? -eq 1 ]; then sudo lsof /var/lib/dpkg/lock-frontend; sudo apt install dos2unix; fi",
      "sudo dos2unix ${local.cac_provisioning_script}",
      "sudo bash ${local.cac_provisioning_script}",
    ]
  }
}

