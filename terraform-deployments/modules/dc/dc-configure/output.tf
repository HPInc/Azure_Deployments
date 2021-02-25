/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

output "service-configured" {
  description = "The domain controlller has been configured dependency"
  value = [
    null_resource.az-configure-domain-controller.id,
    null_resource.az-restart-domain-controller.id,
    null_resource.az-setup-admins-domain-controller.id
  ]
}