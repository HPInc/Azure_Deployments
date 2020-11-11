/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
    password = var.cac_admin_password
    host     = var.cac_ips[count.index]
    port     = "22"
    #private_key = file("${path.module}/tera_private_key.ppk")
  }

  provisioner "file" {
    content     = templatefile("${path.module}/files/cac-startup.sh", {
      cac_installer_url           = var.cac_installer_url
      domain_controller_ip        = var.domain_controller_ip
      ad_service_account_username = var.ad_service_account_username
      ad_service_account_password = var.ad_service_account_password
      domain_name                 = var.domain_name
      cam_url                     = var.cam_url
      cac_token                   = var.cac_configuration[count.index].cac_token
      domain_group                = var.domain_group
      pcoip_registration_code     = var.pcoip_registration_code
      ssl_key                     = var.ssl_key
      ssl_cert                    = var.ssl_cert
      application_id              = var.application_id
      aad_client_secret           = var.aad_client_secret
      tenant_id                   = var.tenant_id
      pcoip_secret_key            = var.pcoip_secret_id
      ad_pass_secret_key          = var.ad_pass_secret_id
      cac_token_secret_key        = var.cac_token_secret_id
      _artifactsLocation          = var._artifactsLocation
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
    password = var.cac_admin_password
    host     = var.cac_ips[count.index]
    port     = "22"
    #private_key = file("${path.module}/tera_private_key.ppk")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm /var/lib/apt/lists/*",
      "sudo apt -y update",
      "sudo lsof /var/lib/dpkg/lock-frontend",
      "sudo apt install dos2unix",
      "if [ $? -eq 1 ]; then sudo lsof /var/lib/dpkg/lock-frontend; sudo apt install dos2unix; fi",
      "sudo dos2unix ${local.startup_cac_filename}",
      "sudo bash ${local.startup_cac_filename}",
    ]
  }
}

