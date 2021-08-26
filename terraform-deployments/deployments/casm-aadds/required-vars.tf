variable "aadds_rg_name" {
  description = "Name of the resource group the AADDS will belong in"
  type        = string
  default     = "BY_AAD_DS_Teradici"
}

variable "aadds_vnet_name" {
  description = "Name of the VNET the AADDS will belong in"
  type        = string
  default     = "AAD_DS_TeraVNet"
}

variable "aadds_location" {
    description = "Location of the AADDS"
    type        = string
}

variable "aadds_domain_name" {
    description = "Domain name of the AADDS"
    type        = string
}

variable "pfx_cert_password" {
  description = "Password of the PFX certificate"
  type        = string
}

variable "application_id" {
  type = string
}

variable "aad_client_secret" {
  type = string
}

