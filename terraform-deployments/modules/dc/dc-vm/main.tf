/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_windows_virtual_machine" "domain-controller-sp" {
  count = var.managed_identity_id == "" ? 1 : 0
  depends_on = [var.dc_vm_depends_on]

  name                = local.virtual_machine_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.dc_machine_type[0]
  admin_username      = var.ad_admin_username
  admin_password      = local.ad_admin_password
  custom_data         = local.custom_data

  network_interface_ids = [
    var.nic_id,
  ]

  os_disk {
    name                 = "dc-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  additional_unattend_content {
    content = local.auto_logon_data
    setting = "AutoLogon"
  }

  additional_unattend_content {
    content = local.first_logon_data
    setting = "FirstLogonCommands"
  }
}

resource "azurerm_windows_virtual_machine" "domain-controller-im" {
  count = var.managed_identity_id != "" ? 1 : 0
  depends_on = [var.dc_vm_depends_on]

  name                = local.virtual_machine_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.dc_machine_type[0]
  admin_username      = var.ad_admin_username
  admin_password      = local.ad_admin_password
  custom_data         = local.custom_data

  network_interface_ids = [
    var.nic_id,
  ]

  os_disk {
    name                 = "dc-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  additional_unattend_content {
    content = local.auto_logon_data
    setting = "AutoLogon"
  }

  additional_unattend_content {
    content = local.first_logon_data
    setting = "FirstLogonCommands"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [
      var.managed_identity_id
      ]
  }
}

resource "azurerm_resource_group_template_deployment" "shutdown_schedule_template" {
  name                = var.managed_identity_id != "" ? "${azurerm_windows_virtual_machine.domain-controller-im[0].name}-shutdown-schedule-template" : "${azurerm_windows_virtual_machine.domain-controller-sp[0].name}-shutdown-schedule-template"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  parameters_content = jsonencode({
    "location"                       = {value = var.location}
    "virtualMachineName"             = var.managed_identity_id != "" ? {value = azurerm_windows_virtual_machine.domain-controller-im[0].name} : {value = azurerm_windows_virtual_machine.domain-controller-sp[0].name}
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
