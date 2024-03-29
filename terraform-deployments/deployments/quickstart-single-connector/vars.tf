/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "location" {
  description = "Location for resources. e.g.: 'westus2'"
}

variable "auth_method" {
  description = "Authentication method either managed identity or service principal"
}