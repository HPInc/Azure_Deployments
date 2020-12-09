/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "null_resource" "az-centos-script-download" {
  depends_on = [
    var.centos_host_configure_depends_on
  ]

  # Create for each centos os workstation
  count = length(var.centos-host-vm-ids)

  # Trigger download of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.centos-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunShellScript --name \"${var.centos-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\" --scripts \"mkdir -p ${local.deploy_temp_dir} ; wget ${local.centos_gfx_provisioning_script_uri} -O ${local.centos_gfx_provisioning_script_destination} ; wget ${local.centos_provisioning_script_uri} -O ${local.centos_provisioning_script_destination}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-run-centos-gfx-provisioning-script" {
  # Script execution happens after download
  depends_on = [
    var.centos_host_configure_depends_on,
    null_resource.az-centos-script-download
  ]

  # Create for each window os workstation
  count = length(local.filtered_gfx_workstations)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.centos-host-vm-ids[local.filtered_gfx_workstations[count.index].index]
  }

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunShellScript --name \"${var.centos-host-vm-names[local.filtered_gfx_workstations[count.index].index]}\" -g ${var.resource_group_name} --scripts \"sudo dos2unix ${local.centos_gfx_provisioning_script_destination} ; echo ${var.admin_password} | sudo -S chmod +x ${local.centos_gfx_provisioning_script_destination} ; echo ${var.admin_password} | sudo bash ${local.centos_gfx_provisioning_script_destination}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

# GFX driver install stage 3
resource "null_resource" "az-run-centos-gfx-provisioning-script-restart" {
  # Script execution happens after deployment script run is successful
  depends_on = [
    var.centos_host_configure_depends_on,
    null_resource.az-run-centos-gfx-provisioning-script
  ]

  # Create for each window os workstation
  count = length(local.filtered_gfx_workstations)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.centos-host-vm-ids[local.filtered_gfx_workstations[count.index].index]
  }

  provisioner "local-exec" {
    command     = "az vm restart --name \"${var.centos-host-vm-names[local.filtered_gfx_workstations[count.index].index]}\" -g \"${var.resource_group_name}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-run-centos-provisioning" {
  # Script execution happens after download
  depends_on = [
    var.centos_host_configure_depends_on,
    null_resource.az-centos-script-download,
    null_resource.az-run-centos-gfx-provisioning-script,
    null_resource.az-run-centos-gfx-provisioning-script-restart,
  ]

  # Create for each centos os workstation
  count = length(var.centos-host-vm-ids)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.centos-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunShellScript --name ${var.centos-host-vm-names[count.index]} -g ${var.resource_group_name} --scripts \"sudo dos2unix ${local.centos_provisioning_script_destination} ; echo ${var.admin_password} | sudo -S chmod +x ${local.centos_provisioning_script_destination} ; echo ${var.admin_password} | sudo bash ${local.centos_provisioning_script_destination} ${local.pcoip_agent_deploy_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-run-centos-provisioning-restart" {
  # Script execution happens after deployment script run is successful
  depends_on = [
    var.centos_host_configure_depends_on,
    null_resource.az-run-centos-provisioning
  ]

  # Create for each window os workstation
  count = length(var.centos-host-vm-ids)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.centos-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm restart --name \"${var.centos-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}
