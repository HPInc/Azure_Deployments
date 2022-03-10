/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "cac_configure_depends_on" {
  description = "Value that internal module components can use as a dependency for externally created recources"
  type        = any
  default     = null
}

variable "ssl_key" {
  description = "SSL private key for the Connector"
  default     = ""
}

variable "ssl_cert" {
  description = "SSL certificate for the Connector"
  default     = ""
}

variable "cac_installer_url" {
  description = "Location of the Cloud Access Connector installer"
  default     = "https://dl.teradici.com/yj39yHtgj68Uv2Qf/cloud-access-connector/raw/names/cloud-access-connector-linux-tgz/versions/latest/cloud-access-connector_latest_Linux.tar.gz"
}

variable "cas_mgr_url" {
  description = "CAS Manager URL"
  default     = "https://cas.teradici.com"
}

variable "lls_ip" {
  description = "Internal IP of the PCoIP License Server"
  default     = ""
}

variable "cas_mgr_insecure" {
  description = "Allow unverified SSL access to CAS Manager"
  type        = bool
  default     = false
}
