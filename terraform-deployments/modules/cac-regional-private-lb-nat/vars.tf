/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

variable "aad_client_secret" {
  description = "The client secret of your app registration in AAD"
  type        = string
}

variable "ad_pass_secret_name" {
  description = "Name of ad admin password"
}

variable "ad_service_account_username" {
  description = "Active Directory Service Account username"
  type        = string
}

variable "ad_service_account_password" {
  description = "Active Directory Service Account password"
  type        = string
}

variable "application_id" {
  description = "The application (client) ID of your app registration in AAD"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of virtual network"
}

variable "private_container_url" {
  description = "URL of the private storage."
}

variable "cac_admin_user" {
  description = "Username of the Cloud Access Connector Administrator"
  type        = string
}

variable "cac_subnet_cidr" {
  description = "Subnet for the region specific cac"
}

variable "cac_admin_password" {
  description = "Password for the Administrator of the Cloud Access Connector VM"
  type        = string
}

variable "cac_installer_url" {
  description = "Location of the Cloud Access Connector installer"
  default     = "https://dl.teradici.com/yj39yHtgj68Uv2Qf/cloud-access-connector/raw/names/cloud-access-connector-linux-tgz/versions/latest/cloud-access-connector_latest_Linux.tar.gz"
}

variable "instance_count" {
  description = "Number of Cloud Access Connector instances to deploy in each zone"
}

variable "cac_subnet_name" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
  default     = "cac-subnet"
}

variable "cas_mgr_deployment_sa_file" {
  description = "Filename of CAS Manager Deployment Service Account JSON key in bucket"
  type        = string
}

variable "cas_mgr_insecure" {
  description = "Allow unverified SSL access to CAS Manager"
  type        = bool
  default     = false
}

variable "cas_mgr_setup_script_url" {
  description = "URL for CAS Manager setup script"
  type        = string
}

variable "cas_mgr_url" {
  description = "CAS Manager URL"
  default     = "https://cas.teradici.com"
}

variable "cas_mgr_script" {
  description = "Name of script to interact with CAS Manager"
  type        = string
}

variable "disk_size_gb" {
  description = "Disk size (GB) of the Cloud Access Connector"
  default     = "50"
}

variable "domain_controller_ip" {
  description = "Internal IP of the Domain Controller"
  type        = string
}

variable "domain_group" {
  description = "Active Directory Distinguished Name for the User Group to log into the CAS Management Interface. Default is 'Domain Admins'. (eg, 'CN=CASM Admins,CN=Users,DC=example,DC=com')"
  default     = "Domain Admins"
}

variable "domain_name" {
  description = "Name of the domain to join"
  type        = string
}

variable "key_vault_id" {
  description = "Key vault ID for ad admin password"
}

variable "resource_group_name" {
  description = "Name of the resource group"
}

variable "lls_ip" {
  description = "Internal IP of the PCoIP License Server"
  default     = ""
}

variable "location" {
  description = "Location of CAC virtual machine"
}

variable "machine_type" {
  description = "Machine type for the Cloud Access Connector"
  default     = ["Standard_B2ms"]
}

variable "network_security_group_id" {
  description = "The network security group id"
}

variable "prefix" {
  description = "Prefix to add to name of new resources. Must be <= 9 characters."
}

variable "ssl_key" {
  description = "SSL private key for the Connector"
  default     = ""
}

variable "ssl_cert" {
  description = "SSL certificate for the Connector"
  default     = ""
}

variable "storage_account_name" {
  description = "Name of storage account that holds scripts"
}

variable "tenant_id" {
  description = "The directory (tenant) ID of your app registration in AAD"
  type        = string
}

variable "storage_connection_string" {
  description = "Connection string used to create a SAS token."
}

variable "private_container_name" {
  description = "Name of container which stores .json key file."
}

variable "aadds_resource_group" {
  description = "Name of the resource group the AADDS belongs in"
  default     = ""
}

variable "cas_mgr_internal_ip" {
  description = "Internal IP of the CAS manager"
  type        = string
}

variable "cas_mgr_public_ip" {
  description = "Public IP of the CAS manager"
  type        = string
}

variable "cas_mgr_public_ip_id" {
  description = "ID of the Public IP of the CAS manager"
  type        = string
}

variable "cac_subnet_depends_on" {
  description = "Modules that the subnet requires as a dependency"
  type        = any
  default     = null
}

variable "lb_id" {
  description = "ID of Load Balancer"
  type        = string
}

variable "cac_public" {
  description = "Public IPs of the Firewall which NAT to the internal CAC IPs"
  type        = any
}


variable "cac_nat_depends_on" {
  type        = any
  default     = null
}

variable "probe_id" {
  type = string
  default = ""
}