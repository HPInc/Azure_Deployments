/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "null_resource" "upload-scripts" {
  # depends_on = [
  #   var.dc_vm_setup_depends_on]

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = var.domain_controller_virtual_machine_public_ip
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "file" {
    content     = data.template_file.setup-script.rendered
    destination = local.setup_file
  }

  provisioner "file" {
    content     = data.template_file.setup-add-admins-script.rendered
    destination = local.setup_add_admin_file
  }

  provisioner "file" {
    content     = data.template_file.new-domain-users-script.rendered
    destination = local.new_domain_users_file
  }
}

resource "null_resource" "upload-domain-users-list" {
  depends_on = [null_resource.upload-scripts]

  count = local.new_domain_users

  connection {
    type     = "winrm"
    user     = var.ad_admin_username
    password = local.use_secret_or_not.ad_admin_password
    host     = var.domain_controller_virtual_machine_public_ip
    port     = "5986"
    https    = true
    insecure = true
  }

  provisioner "file" {
    source      = var.active_directory_domain_users_list_file
    destination = local.domain_users_list_file
  }
}
