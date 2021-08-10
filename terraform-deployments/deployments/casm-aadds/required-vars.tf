variable "subscription_id" {
  description = "Subscription ID of the directory the AADDS will be deployed in"
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

variable "pfx_cert_password" {
  description = "Password of the PFX certificate"
  type        = string
}