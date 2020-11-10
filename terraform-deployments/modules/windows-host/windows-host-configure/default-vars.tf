/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "windows_host_configure_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type    = any
  default = null
}