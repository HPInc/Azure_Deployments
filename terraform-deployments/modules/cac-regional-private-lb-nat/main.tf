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

resource "time_offset" "start" {
  offset_days = -7
}

resource "time_offset" "expiry" {
  offset_days = 7
}

data "azurerm_storage_account_blob_container_sas" "token" {

  count = var.instance_count

  connection_string = var.storage_connection_string
  container_name    = var.private_container_name
  https_only        = true

  start  = time_offset.start.rfc3339
  expiry = time_offset.expiry.rfc3339

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
  depends_on = [
    var.cac_subnet_depends_on
  ]
  name                 = "${var.cac_subnet_name}-${var.location}"
  address_prefixes     = var.cac_subnet_cidr
  resource_group_name  = var.aadds_resource_group == "" ? var.resource_group_name : var.aadds_resource_group
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_subnet_network_security_group_association" "cac" {
  subnet_id                 = azurerm_subnet.cac.id
  network_security_group_id = var.network_security_group_id
}


resource "azurerm_network_interface" "cac-nic" {

  count = var.instance_count

  name                = "${local.prefix}cac-nic-${var.location}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Dynamic"
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

resource "azurerm_lb_nat_rule" "cac_nat" {
  count = var.instance_count
  depends_on = [var.cac_nat_depends_on, azurerm_linux_virtual_machine.cac-vm, azurerm_linux_virtual_machine.cac-vm]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "PCoIP-cac-${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association" {
  count = var.instance_count
  depends_on = [var.cac_nat_depends_on, azurerm_linux_virtual_machine.cac-vm, azurerm_linux_virtual_machine.cac-vm]
  network_interface_id  = azurerm_network_interface.cac-nic[count.index].id
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat[count.index].id
}

resource "azurerm_lb_nat_rule" "cac_nat_udp" {
  count = var.instance_count
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association, azurerm_linux_virtual_machine.cac-vm]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "PCoIP_UDP-cac-${count.index}"
  protocol                       = "Udp"
  frontend_port                  = 4172
  backend_port                   = 4172
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association_udp" {
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association, azurerm_linux_virtual_machine.cac-vm]
  count = var.instance_count
  
  network_interface_id  = azurerm_network_interface.cac-nic[count.index].id
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat_udp[count.index].id
}

resource "azurerm_lb_nat_rule" "cac_nat_ssh" {
  count = var.instance_count
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association_udp, azurerm_linux_virtual_machine.cac-vm]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "ssh-cac-${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "ip-config-cac-${count.index}"
}

resource "azurerm_network_interface_nat_rule_association" "cac_association_ssh" {
  count = var.instance_count
  depends_on = [azurerm_network_interface_nat_rule_association.cac_association_udp, azurerm_linux_virtual_machine.cac-vm]
  network_interface_id  = azurerm_network_interface.cac-nic[count.index].id
  ip_configuration_name = "primary"
  nat_rule_id           = azurerm_lb_nat_rule.cac_nat_ssh[count.index].id
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = var.lb_id
  name            = "backend-address-pool"
}

# Optional load balancer vm association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = var.instance_count

  network_interface_id    = azurerm_network_interface.cac-nic[count.index].id
  ip_configuration_name   = "primary"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}


resource "azurerm_lb_rule" "allow_port_443" {
  depends_on                     = [var.cac_nat_depends_on, azurerm_network_interface_backend_address_pool_association.main, azurerm_network_interface_nat_rule_association.cac_association_ssh, azurerm_linux_virtual_machine.cac-vm]
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = var.lb_id
  name                           = "allow-https-${var.location}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "loadbalancer-frontend"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
  probe_id                       = var.probe_id
  load_distribution              = "SourceIPProtocol"
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
    azurerm_linux_virtual_machine.cac-vm,
    azurerm_network_interface_nat_rule_association.cac_association_ssh
  ]

  count = var.ssl_key == "" ? 0 : var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_public[count.index].ip_address
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
    azurerm_linux_virtual_machine.cac-vm,
    azurerm_network_interface_nat_rule_association.cac_association_ssh
  ]

  count = var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_public[count.index].ip_address
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
      external_pcoip_ip           = var.cac_public[count.index].ip_address,
      sas_token                   = data.azurerm_storage_account_blob_container_sas.token[count.index].sas
      private_container_url       = var.private_container_url,
    })
    destination = "/home/${var.cac_admin_user}/cac-provisioning.sh"
  }
}

resource "null_resource" "run-cac-provisioning-script" {

  depends_on = [
    null_resource.upload-provisioning-script,
    azurerm_network_interface_nat_rule_association.cac_association_ssh
  ]

  count = var.instance_count

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_public[count.index].ip_address
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

