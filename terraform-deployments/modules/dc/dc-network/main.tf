/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

resource "azurerm_virtual_network" "network" {
  depends_on = [var.dc_network_depends_on]

  name                = var.vnet_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = var.resource_group_name
  dns_servers         = ["${var.dc_private_ip}", "168.63.129.16"]
}

resource "azurerm_subnet" "dc" {
  depends_on = [var.dc_network_depends_on]

  name                 = var.dc_subnet_name
  address_prefix       = var.dc_subnet_cidr
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
}

resource "azurerm_network_security_group" "nsg" {
  depends_on = [var.dc_network_depends_on]

  name                = join("-", [var.prefix, "dc-nsg"])
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "nsg_5985" {
  depends_on = [var.dc_network_depends_on]

  name                        = "Open Port 5985"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "nsg_5986" {
  depends_on = [var.dc_network_depends_on]

  name                        = "Open Port 5986"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5986"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# For debugging only
resource "azurerm_network_security_rule" "nsg_3389" {
  depends_on = [var.dc_network_depends_on]

  name                        = "Open Port 3389"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "network" {
  depends_on = [var.dc_network_depends_on]

  subnet_id                 = azurerm_subnet.dc.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet" "workstation" {
  depends_on = [var.dc_network_depends_on]

  name                 = var.workstation_subnet_name
  address_prefix       = "10.0.2.0/24"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.network.name
}

resource "azurerm_network_interface" "dc_nic" {
  depends_on = [var.dc_network_depends_on]

  name                = join("-", [var.prefix, "dc-primary"])
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "primary"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.dc_private_ip
    public_ip_address_id          = azurerm_public_ip.dc_ip.id
    subnet_id                     = azurerm_subnet.dc.id
  }

  # Workaround do disassociate public ip from nic when destroying
  provisioner "local-exec" {
    when    = destroy
    command = "az network nic ip-config create -g ${self.resource_group_name} -n primary --nic-name ${self.name} --private-ip-address ${self.ip_configuration[0].private_ip_address}"
  }
}

resource "azurerm_public_ip" "dc_ip" {
  depends_on = [var.dc_network_depends_on]

  name                    = "public-dc-ip"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}
