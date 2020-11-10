/*
 * Copyright (c) 2020 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "vnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "vnet"
}

variable "cac_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "cac-subnet"
}

variable "dc_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "dc-subnet"
}

variable "workstation_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "workstation-subnet"
}

variable "cam_url" {
  description = "Cloud Access Manager URL"
  default     = "https://cam.teradici.com"
}

variable "pcoip_agent_location" {
  description = "URL of Teradici PCoIP Standard Agent"
  default     = "https://downloads.teradici.com/win/stable/"
}

variable "domain_group" {
  description = "Active Directory Distinguished Name for the User Group to log into the CAM Management Interface. Default is 'Domain Admins'. (eg, 'CN=CAM Admins,CN=Users,DC=example,DC=com')"
  default     = "Domain Admins"
}

variable "instance_count" {
  description = "Number of Cloud Access Connectors to deploy"
  default     = 1
}

variable "cac_host_name" {
  description = "Name to give the host"
  default     = "vm-cac"
}

variable "cac_machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = "Standard_D2s_v3"
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
  default     = "50"
}

variable "cac_installer_url" {
  description = "Location of the Cloud Access Connector installer"
  default     = "https://teradici.bintray.com/cloud-access-connector/cloud-access-connector-0.1.1.tar.gz"
}

variable "ssl_key" {
  description = "SSL private key for the Connector"
  default     = ""
}

variable "ssl_cert" {
  description = "SSL certificate for the Connector"
  default     = ""
}

variable "dc_private_ip" {
  description = "Static internal IP address for the Domain Controller"
  default     = "10.0.1.4"
}

variable "cac_private_ip" {
  description = "Static internal IP address for the Cloud Access Controller"
  default     = "10.0.3.4"
}

variable "dc_subnet_cidr" {
  description = "CIDR for subnet containing the Domain Controller"
  default     = "10.0.1.0/24"
}

variable "ws_subnet_cidr" {
  description = "CIDR for subnet containing the Workstations"
  default     = "10.0.2.0/24"
}

variable "cac_subnet_cidr" {
  description = "CIDR for subnet containing the Domain Controller"
  default     = "10.0.3.0/24"
}

variable "allowed_client_cidrs" {
  description = "Open VPC firewall to allow PCoIP connections from these IP Addresses or CIDR ranges. e.g. 'a.b.c.d', 'e.f.g.0/24'"
  default     = "0.0.0.0/0"
}

variable "dc_machine_type" {
  description = "Machine type for Domain Controller"
  default     = "Standard_F2"
}

variable "domain_users_list" {
  description = "Active Directory users to create, in CSV format"
  type        = string
  default     = ""
}

variable "_artifactsLocationSasToken" {
  description = "Sas Token of the URL is optional, only if required for security reasons"
  type        = string
  default     = ""
}

variable "create_debug_public_ips" {
  description = "Debug flag to create public ip addresses for the domain controller and cac VMs"
  type        = bool
  default     = false
}

variable "create_debug_rdp_access" {
  description = "Debug flag to create RDP access to the domain controller"
  type        = bool
  default     = false
}
