/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
 
variable "centos_host_network_depends_on" {
    description = "Value that internal module components can use as a dependency for externally created resources"
    type        = any
    default     = null
}