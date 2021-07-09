/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

locals {
  network_security_rule_prefixes = setproduct(range(0, length(var.locations)), range(0, length(var.locations)))
  prefix                         = var.prefix != "" ? "${var.prefix}-" : ""
}
