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

variable "tls_key" {
  description = "TLS private key for the Connector"
  default     = ""
}

variable "tls_cert" {
  description = "TLS certificate for the Connector"
  default     = ""
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
  description = "Allow unverified TLS access to CAS Manager"
  type        = bool
  default     = false
}

variable "teradici_download_token" {
  description = "Token used to download from Teradici"
  default     = "yj39yHtgj68Uv2Qf"
}
