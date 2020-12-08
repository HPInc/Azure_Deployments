/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  # Pcoip script parameters
  pcoip_agent_deploy_script_params = "-a ${var.pcoip_registration_code} -b ${var.ad_service_account_password} -c ${var.ad_service_account_username} -d ${var.domain_name} -e ${var.domain_controller_ip} -f ${var.application_id} -g ${var.aad_client_secret} -h ${var.tenant_id} -i ${var.pcoip_secret_id} -j ${var.ad_pass_secret_id}"

  # Upload destination on the host machine
  deploy_temp_dir = "/home/${var.admin_name}/Temp"

  # Centos utility script
  centos_utility_script             = "centos-utility.sh"
  centos_utility_script_uri         = "${var._artifactsLocation}${local.centos_utility_script}"
  centos_utility_script_destination = "${local.deploy_temp_dir}/${local.centos_utility_script}"

  # Centos provisioning script
  centos_provisioning_script             = "centos-provisioning.sh"
  centos_provisioning_script_uri         = "${var._artifactsLocation}${local.centos_provisioning_script}"
  centos_provisioning_script_destination = "${local.deploy_temp_dir}/${local.centos_provisioning_script}"

  # Centos graphics provisioning script
  centos_gfx_provisioning_script             = "centos-gfx-provisioning.sh"
  centos_gfx_provisioning_script_uri         = "${var._artifactsLocation}${local.centos_gfx_provisioning_script}"
  centos_gfx_provisioning_script_destination = "${local.deploy_temp_dir}/${local.centos_gfx_provisioning_script}"

  # Figure out what graphics workstations we need to configure
  filtered_gfx_workstations = [for item in var.workstations : item if item.isGFXHost == true]

  # Determine OS to use correct command interpreter
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}
