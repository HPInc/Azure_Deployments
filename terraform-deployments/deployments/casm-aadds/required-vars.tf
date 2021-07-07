variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "aadds_rg_name" {
  description = "Name of the resource group the AADDS will belong in"
  type        = string
}

variable "aadds_vnet_name" {
  description = "Name of the VNET the AADDS will belong in"
  type        = string
}

variable "aadds_location" {
    description = "Location of the AADDS"
    type        = string
}

variable "aadds_domain_name" {
    description = "Domain name of the AADDS"
    type        = string
}
