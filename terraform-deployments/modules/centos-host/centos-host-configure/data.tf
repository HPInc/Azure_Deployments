/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  # pcoip script parameters
  pcoip_agent_deploy_script_params = "-a ${var.pcoip_registration_code} -b ${var.ad_service_account_password} -c ${var.ad_service_account_username} -d ${var.domain_name} -e ${var.domain_controller_ip} -f ${var.application_id} -g ${var.aad_client_secret} -h ${var.tenant_id} -i ${var.pcoip_secret_id} -j ${var.ad_pass_secret_id}"

  # upload destination on the host machine
  deploy_temp_dir = "/home/${var.admin_name}/Temp"

  # utility script
  centos_utility_script             = "centos-utility.sh"
  centos_utility_script_uri         = "${var._artifactsLocation}${local.centos_utility_script}"
  centos_utility_script_destination = "${local.deploy_temp_dir}/${local.centos_utility_script}"

  # gfx stage 1 script
  centos_gfx_stage1_script             = "centos-gfx-install-stage1.sh"
  centos_gfx_stage1_script_uri         = "${var._artifactsLocation}${local.centos_gfx_stage1_script}"
  centos_gfx_stage1_script_destination = "${local.deploy_temp_dir}/${local.centos_gfx_stage1_script}"

  # gfx stage 2 script
  centos_gfx_stage2_script             = "centos-gfx-install-stage2.sh"
  centos_gfx_stage2_script_uri         = "${var._artifactsLocation}${local.centos_gfx_stage2_script}"
  centos_gfx_stage2_script_destination = "${local.deploy_temp_dir}/${local.centos_gfx_stage2_script}"

  # gfx stage 3 script
  centos_gfx_stage3_script             = "centos-gfx-install-stage3.sh"
  centos_gfx_stage3_script_uri         = "${var._artifactsLocation}${local.centos_gfx_stage3_script}"
  centos_gfx_stage3_script_destination = "${local.deploy_temp_dir}/${local.centos_gfx_stage3_script}"

  # Stage 1 setup script
  centos_stage1_script             = "centos-startup-stage1.sh"
  centos_stage1_script_uri         = "${var._artifactsLocation}${local.centos_stage1_script}"
  centos_stage1_script_destination = "${local.deploy_temp_dir}/${local.centos_stage1_script}"

  # Stage 2 setup script
  centos_stage2_script             = "centos-startup-stage2.sh"
  centos_stage2_script_uri         = "${var._artifactsLocation}${local.centos_stage2_script}"
  centos_stage2_script_destination = "${local.deploy_temp_dir}/${local.centos_stage2_script}"

  # Figure out what graphics workstations we need to configure
  filtered_gfx_workstations = [for item in var.workstations : item if item.isGFXHost == true]

  # Determine OS to use correct command interpreter
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}
