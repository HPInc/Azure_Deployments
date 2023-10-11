/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  startup_cac_filename = "cac-startup.sh"
  tls_key_filename     = var.tls_key == "" ? "" : basename(var.tls_key)
  tls_cert_filename    = var.tls_cert == "" ? "" : basename(var.tls_cert)
  ad_admin_password    = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].id)
  cac_admin_password   = var.key_vault_id == "" ? var.ad_service_account_password : tostring(data.azurerm_key_vault_secret.ad-pass[0].value)
}

data "azurerm_key_vault_secret" "ad-pass" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = var.ad_pass_secret_name
  key_vault_id = var.key_vault_id
}

resource "null_resource" "upload-tls" {

  depends_on = [
    var.cac_configure_depends_on
  ]

  count = var.tls_key == "" ? 0 : length(var.cac_vm_ids)

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_ips[count.index]
    port     = "22"
  }

  provisioner "file" {
    source      = var.tls_key
    destination = "/tmp/${local.tls_key_filename}"
  }

  provisioner "file" {
    source      = var.tls_cert
    destination = "/tmp/${local.tls_cert_filename}"
  }
}

resource "null_resource" "upload-scripts" {
  depends_on = [
    var.cac_configure_depends_on
  ]

  count = length(var.cac_vm_ids)

  # Trigger script if the vm changes or the cac token changes
  triggers = {
    cac_vm_id = var.cac_vm_ids[count.index]
    cac_token = var.cac_configuration[count.index].cac_token
  }

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_ips[count.index]
    port     = "22"
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/cac-startup.sh", {
      cas_mgr_insecure            = var.cas_mgr_insecure
      domain_controller_ip        = var.domain_controller_ip
      ad_service_account_username = var.ad_service_account_username
      ad_service_account_password = local.ad_admin_password
      domain_name                 = var.domain_name
      computers_dn                = "dc=${replace(var.domain_name, ".", ",dc=")}"
      users_dn                    = "dc=${replace(var.domain_name, ".", ",dc=")}"
      cas_mgr_url                 = var.cas_mgr_url
      cac_token                   = var.cac_configuration[count.index].cac_token
      tls_key                     = local.tls_key_filename
      tls_cert                    = local.tls_cert_filename
      application_id              = var.application_id
      aad_client_secret           = var.aad_client_secret
      tenant_id                   = var.tenant_id
      lls_ip                      = var.lls_ip
      teradici_download_token     = var.teradici_download_token
    })
    destination = "/home/${var.cac_admin_user}/cac-startup.sh"
  }
}

resource "null_resource" "run-cac-startup-script" {

  count = length(var.cac_vm_ids)

  # Trigger script run if the script has been uploaded
  triggers = {
    instance_id = null_resource.upload-scripts[count.index].id
  }

  connection {
    type     = "ssh"
    user     = var.cac_admin_user
    password = local.cac_admin_password
    host     = var.cac_ips[count.index]
    port     = "22"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf -y -q update",
      "sudo dnf check -v",
      "sudo dnf install -y dos2unix",
      "if [ $? -eq 1 ]; then sudo dnf check -v; sudo dnf install -y dos2unix; fi",
      "sudo dos2unix ${local.startup_cac_filename}",
      "sudo bash ${local.startup_cac_filename}",
    ]
  }
}

