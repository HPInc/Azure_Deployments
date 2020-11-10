/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "cac-vm-configure" {
  description = "Value to be used as a dependency on further resources"
  value       = [for item in null_resource.run-cac-startup-script : item.id]
}
