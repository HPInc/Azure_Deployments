/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "dc_configure_depends_on" {
  type    = any
  default = null
}

locals {
  stage1_script_path_on_vm = "C:/Temp/setup.ps1"
  stage2_script_path_on_vm = "C:/Temp/add_admin.ps1"
}