/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  WallPaperJPG              = "img0.jpg"
  PCoIPAgentEXE             = "pcoip-agent-standard_19.11.0.exe"
  pcoip_agent_deploy_script = "DeployPCoIPAgent.ps1"

  WallPaperPath  = "${var._artifactsLocation}${local.WallPaperJPG}${var._artifactsLocationSasToken}"
  PCoIPAgentPath = "${var._artifactsLocation}${local.PCoIPAgentEXE}${var._artifactsLocationSasToken}"

  pcoip_agent_deploy_script_params = "${var.pcoip_registration_code} ${local.PCoIPAgentPath} ${local.PCoIPAgentEXE} ${local.WallPaperPath} ${var.domain_name} ${var.ad_service_account_username} ${var.ad_service_account_password} ${var.application_id} ${var.tenant_id} ${var.aad_client_secret} ${var.pcoip_secret_id} ${var.ad_pass_secret_id}"
  deploy_script_uri                = "${var._artifactsLocation}${local.pcoip_agent_deploy_script}"

  deploy_script_file             = "${var._artifactsLocation}${local.pcoip_agent_deploy_script}"
  deploy_script_file_destination = "C:/Temp/${local.pcoip_agent_deploy_script}"

  deploy_temp_dir = "C:/Temp"

  # Figure out what graphics workstations we need to configure
  filtered_gfx_workstations = [for item in var.workstations : item if item.isGFXHost == true]

  # Determine OS to use correct command interpreter
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}
