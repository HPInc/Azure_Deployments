/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "null_resource" "az-windows-host-driver-installation" {
  # Script execution happens after deployment script run is successful
  depends_on = [
    var.windows_host_configure_depends_on
  ]

  # Create for each window os workstation
  #  count = length(var.windows-host-vm-ids)
  count = length(local.filtered_gfx_workstations)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.windows-host-vm-ids[local.filtered_gfx_workstations[count.index].index]
    resource_group_name = var.resource_group_name
    vm_name             = var.windows-host-vm-names[local.filtered_gfx_workstations[count.index].index]
  }

  provisioner "local-exec" {
    command     = "az vm extension set --vm-name \"${var.windows-host-vm-names[local.filtered_gfx_workstations[count.index].index]}\" --resource-group \"${var.resource_group_name}\" --name \"NvidiaGpuDriverWindows\" --publisher \"Microsoft.HpcCompute\" --version \"1.3\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az vm extension delete --vm-name \"${self.triggers.vm_name}\" --resource-group \"${self.triggers.resource_group_name}\" --name \"NvidiaGpuDriverWindows\""
  }
}

resource "null_resource" "az-windows-host-configure-nvidia-driver-restart" {
  # Script execution happens after deployment script run is successful
  depends_on = [
    var.windows_host_configure_depends_on,
    null_resource.az-windows-host-driver-installation
  ]

  # Create for each window os workstation
  count = length(var.windows-host-vm-ids)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.windows-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm restart --name \"${var.windows-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-windows-host-configure-download" {
  depends_on = [
    var.windows_host_configure_depends_on,
    null_resource.az-windows-host-configure-nvidia-driver-restart
  ]

  # Create for each window os workstation
  count = length(var.windows-host-vm-ids)

  # Trigger download of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.windows-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name \"${var.windows-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\" --scripts \"mkdir -p ${local.deploy_temp_dir};Invoke-WebRequest -UseBasicParsing ${local.deploy_script_file} -OutFile ${local.deploy_temp_dir}/${local.pcoip_agent_deploy_script} -Verbose\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-windows-host-configure-run-deploy" {
  # Script execution happens after download
  depends_on = [
    var.windows_host_configure_depends_on,
    null_resource.az-windows-host-configure-download
  ]

  # Create for each window os workstation
  count = length(var.windows-host-vm-ids)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.windows-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm run-command invoke --command-id RunPowerShellScript --name \"${var.windows-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\" --scripts \"${local.deploy_temp_dir}/${local.pcoip_agent_deploy_script} ${local.pcoip_agent_deploy_script_params}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}

resource "null_resource" "az-windows-host-configure-restart" {
  # Script execution happens after deployment script run is successful
  depends_on = [
    var.windows_host_configure_depends_on,
    null_resource.az-windows-host-configure-download,
    null_resource.az-windows-host-configure-run-deploy
  ]

  # Create for each window os workstation
  count = length(var.windows-host-vm-ids)

  # Trigger the execution of the deploy script if the vm has changed
  triggers = {
    current_instance_id = var.windows-host-vm-ids[count.index]
  }

  provisioner "local-exec" {
    command     = "az vm restart --name \"${var.windows-host-vm-names[count.index]}\" -g \"${var.resource_group_name}\""
    interpreter = local.is_windows ? ["PowerShell", "-Command"] : []
  }
}
