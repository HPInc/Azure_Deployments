/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "uploaded-scripts" {
  description = "The id of the script upload null resource"
  value = null_resource.upload-scripts.id
}

output "uploaded-domain-users-list-count" {
  description = "The id of the domain users list upload null resource"
  value = null_resource.upload-domain-users-list
  #value = "Instances: ${element(null_resource.upload-domain-users-list.*.id, 0)}"
}