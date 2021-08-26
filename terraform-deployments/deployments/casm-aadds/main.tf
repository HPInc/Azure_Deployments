data "http" "myip" {
  url = "https://ipinfo.io/ip"
}

data "external" "os" {
  working_dir = path.module
  program = ["printf", "{\"os\": \"Linux\"}"]
}

locals {
  os = data.external.os.result.os
  check = local.os == "Windows" ? "Windows" : "Linux"
}

resource "azurerm_resource_group" "main" {
	name     = var.aadds_rg_name
	location = var.aadds_location
}

resource "azurerm_virtual_network" "aadds_vnet" {
	name                = var.aadds_vnet_name
	address_space       = ["10.0.0.0/16"]
	location            = azurerm_resource_group.main.location
	resource_group_name = azurerm_resource_group.main.name
      #  dns_servers         = [
      #      "10.0.0.4",
      #      "10.0.0.5"
      #   ]
}

resource "azurerm_subnet" "aadds_subnet" {
	name                 = "AADDS-Subnet"
	resource_group_name = azurerm_resource_group.main.name
	virtual_network_name = azurerm_virtual_network.aadds_vnet.name
	address_prefixes     = ["10.0.0.0/24"]
}


resource "azurerm_network_security_group" "nsg" {
  name                = "aadds-nsg-${azurerm_resource_group.main.location}-2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "nsg_allow_all_vnet" {
  name                       = "allow all vnet"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_ranges    = ["1-65525"]
  source_address_prefix      = "10.0.0.0/16"
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# WinRM port used to upload scripts
resource "azurerm_network_security_rule" "nsg_5985" {
  name                        = "winrm port 5985"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# AADDS Port
resource "azurerm_network_security_rule" "nsg_5986" {
  name                        = "winrm port 5986"
  priority                    = 202
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5986"
  source_address_prefix       = "AzureActiveDirectoryDomainServices"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# SSH port used to upload scripts
resource "azurerm_network_security_rule" "nsg_22" {
  name                        = "ssh port 22"
  priority                    = 203
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = chomp(data.http.myip.body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "network" {
  subnet_id                 = azurerm_subnet.aadds_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "null_resource" "generate_pfx_ps" {
  count = local.check == "Windows" ? 1 : 0
  provisioner "local-exec" {
    command = "powershell.exe .\\generate_pfx.ps1 ${var.aadds_domain_name} ${var.pfx_cert_password}"
  }
}

resource "null_resource" "generate_pfx_bash" {
  count = local.check == "Windows" ? 0 : 1
  provisioner "local-exec" {
    command = "chmod +x ./generate_pfx.sh && ./generate_pfx.sh ${var.aadds_domain_name} ${var.pfx_cert_password}"
  }
}

data "local_file" "pfxfile" {
  depends_on = [null_resource.generate_pfx_ps, null_resource.generate_pfx_bash]
  filename = "${path.module}/cert.pfx"
}

resource "azurerm_resource_group_template_deployment" "aadds" {
  depends_on          = [null_resource.generate_pfx_ps, null_resource.generate_pfx_bash, azurerm_network_security_rule.nsg_5986, azurerm_subnet_network_security_group_association.network, azurerm_network_security_rule.nsg_5985, azurerm_network_security_rule.nsg_22, azurerm_network_security_rule.nsg_allow_all_vnet]
  name                = "aadds_template"
  resource_group_name = azurerm_resource_group.main.name
  template_content    = file("template.json")
  parameters_content  = jsonencode({
    apiVersion              = {value = "2017-06-01"}
    domainConfigurationType = {value = "FullySynced"}
    domainName              = {value = var.aadds_domain_name}
    filteredSync            = {value = "Disabled"}
    location                = {value = azurerm_resource_group.main.location}
    subnetName              = {value = azurerm_subnet.aadds_subnet.name}
    vnetName                = {value = azurerm_virtual_network.aadds_vnet.name}
    vnetResourceGroup       = {value = azurerm_resource_group.main.name}
    pfxCert64               = {value = data.local_file.pfxfile.content_base64}
    pfxPassword             = {value = var.pfx_cert_password}
  })
  deployment_mode = "Incremental"
}

resource "null_resource" "az-configure-aadds" {
  depends_on = [
    azurerm_resource_group_template_deployment.aadds
  ]

  provisioner "local-exec" {
    command = "az network vnet update -g ${var.aadds_rg_name} -n ${var.aadds_vnet_name} --dns-servers 10.0.0.4 10.0.0.5"
  }
}
