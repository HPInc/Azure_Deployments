/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  startup_cac_filename = "cac-startup.sh"
  cac_admin_password   = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
  prefix               = var.prefix != "" ? "${var.prefix}-" : ""
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_linux_virtual_machine" "cac" {
  depends_on = [
    var.cac_depends_on
  ]

  count = length(var.cac_configuration)

  name                            = "${local.prefix}cac-vm-${count.index}"
  location                        = var.cac_configuration[count.index].location
  resource_group_name             = var.resource_group_name
  size                            = var.machine_type[0]
  admin_username                  = var.cac_admin_user
  admin_password                  = local.cac_admin_password
  computer_name                   = "${local.prefix}cac-vm"
  disable_password_authentication = false
  network_interface_ids = [
    var.nic_ids[count.index]
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${local.prefix}cac-vm-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "azurerm_resource_group_template_deployment" "shutdown_schedule_template" {
  depends_on = [
    azurerm_linux_virtual_machine.cac
  ]

  count = length(var.cac_configuration)

  name                = "${azurerm_linux_virtual_machine.cac[count.index].name}-shutdown-schedule-template"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  parameters_content = jsonencode({
    "location"                       = {value = var.cac_configuration[count.index].location}
    "virtualMachineName"             = {value = azurerm_linux_virtual_machine.cac[count.index].name}
    "autoShutdownStatus"             = {value = "Enabled"}
    "autoShutdownTime"               = {value = "18:00"}
    "autoShutdownTimeZone"           = {value = "Pacific Standard Time"}
    "autoShutdownNotificationStatus" = {value = "Disabled"}
    "autoShutdownNotificationLocale" = {value = "en"}
  })

  template_content = <<DEPLOY
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
