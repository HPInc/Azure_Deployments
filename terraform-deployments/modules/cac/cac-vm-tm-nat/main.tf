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

  name                            = "${local.prefix}cac-vm-${var.location}-${count.index}"
  location                        = var.location
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
    name                 = "${local.prefix}cac-osdisk-${var.location}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "azurerm_lb_nat_rule" "cac_nat" {
  count = length(var.cac_configuration)
  depends_on = [var.cac_nat_depends_on, azurerm_linux_virtual_machine.cac]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "PCoIP-cac-${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association" {
  count = length(var.cac_configuration)
  depends_on = [var.cac_nat_depends_on, azurerm_linux_virtual_machine.cac]
  network_interface_id  = var.nic_ids[count.index]
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat[count.index].id
}

resource "azurerm_lb_nat_rule" "cac_nat_udp" {
  count = length(var.cac_configuration)
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association, azurerm_linux_virtual_machine.cac]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "PCoIP_UDP-cac-${count.index}"
  protocol                       = "Udp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association_udp" {
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association, azurerm_linux_virtual_machine.cac]
  count = length(var.cac_configuration)
  
  network_interface_id  = var.nic_ids[count.index]
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat_udp[count.index].id
}

resource "azurerm_lb_nat_rule" "cac_nat_ssh" {
  count = length(var.cac_configuration)
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association_udp, azurerm_linux_virtual_machine.cac]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "ssh-cac-${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association_ssh" {
  count = length(var.cac_configuration)
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association_udp, azurerm_linux_virtual_machine.cac]
  network_interface_id  = var.nic_ids[count.index]
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat_ssh[count.index].id
}

resource "azurerm_lb_backend_address_pool" "main" {
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association_ssh]
  loadbalancer_id = var.lb_id
  name            = "backend-address-pool"
}

# Optional load balancer vm association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = length(var.cac_configuration)

  network_interface_id    = var.nic_ids[count.index]
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_outbound_rule" "cac_outbound" {
  count = length(var.cac_configuration)
  depends_on = [azurerm_network_interface_backend_address_pool_association.main, azurerm_lb_nat_rule.cac_nat]
  loadbalancer_id         = var.lb_id
  name                    = "cac-outbound-${count.index}"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id

  frontend_ip_configuration {
    name = "ip-config-cac-${count.index}"
  }
}

resource "azurerm_lb_rule" "allow_port_443" {
  depends_on                     = [var.cac_nat_depends_on, azurerm_network_interface_backend_address_pool_association.main, azurerm_network_interface_nat_rule_association.cac_association_ssh, azurerm_linux_virtual_machine.cac]
  loadbalancer_id                = var.lb_id
  name                           = "allow-https-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "loadbalancer-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = var.probe_id
  load_distribution              = "SourceIPProtocol"
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
    "location"                       = {value = var.location}
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
