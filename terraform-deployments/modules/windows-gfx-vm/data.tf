/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  pcoip_agent_deploy_script = "windows-gfx-provisioning.ps1"

  nvidia_driver_url = "https://go.microsoft.com/fwlink/?linkid=874181"
  nvidia_driver_filename = "452.57_grid_win10_server2016_server2019_64bit_international.exe"

  pcoip_agent_deploy_script_params = "${var.pcoip_registration_code} ${var.domain_name} ${var.ad_service_account_username} ${var.ad_service_account_password} ${local.nvidia_driver_url} ${local.nvidia_driver_filename} ${var.application_id} ${var.tenant_id} ${var.aad_client_secret} ${var.pcoip_secret_id} ${var.ad_pass_secret_id}"
  deploy_script_uri                = "${var._artifactsLocation}${local.pcoip_agent_deploy_script}"

  deploy_script_file             = "${var._artifactsLocation}${local.pcoip_agent_deploy_script}"
  deploy_script_file_destination = "C:/Temp/${local.pcoip_agent_deploy_script}"

  deploy_temp_dir = "C:/Temp"

  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}
