/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "azurerm_subscription" "current" {
}

resource "null_resource" "az-configure-domain-controller" {
  # depends_on = [
  #   var.dc_configure_depends_on
  # ]

  provisioner "local-exec" {
    command = "az vm run-command invoke --command-id RunPowerShellScript --name ${var.domain_controller_virtual_machine_name} -g ${var.resource_group_name}  --scripts ${local.stage1_script_path_on_vm} --subscription ${data.azurerm_subscription.current.subscription_id}"
  }
}

resource "null_resource" "az-restart-domain-controller" {
  depends_on = [
    null_resource.az-configure-domain-controller
  ]

  provisioner "local-exec" {
    command = "az vm restart --name ${var.domain_controller_virtual_machine_name} -g ${var.resource_group_name} --subscription ${data.azurerm_subscription.current.subscription_id}"
  }
}

resource "null_resource" "az-setup-admins-domain-controller" {
  depends_on = [
    null_resource.az-restart-domain-controller
  ]

  provisioner "local-exec" {
    command = "az vm run-command invoke --command-id RunPowerShellScript --name ${var.domain_controller_virtual_machine_name} -g ${var.resource_group_name}  --scripts ${local.stage2_script_path_on_vm} --subscription ${data.azurerm_subscription.current.subscription_id}"
  }
}

resource "null_resource" "az-setup-domain-users" {
  depends_on = [
    null_resource.az-setup-admins-domain-controller
  ]

  provisioner "local-exec" {
    command = "az vm run-command invoke --command-id RunPowerShellScript --name ${var.domain_controller_virtual_machine_name} -g ${var.resource_group_name}  --scripts ${local.stage3_script_path_on_vm} --subscription ${data.azurerm_subscription.current.subscription_id}"
  }
}
