/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "vm-configured" {
  description = "The vm has been configured dependency"
  value = {}

  depends_on = [
    null_resource.az-windows-host-configure-download,
    null_resource.az-windows-host-configure-run-deploy,
    null_resource.az-windows-host-configure-restart
  ]
}
