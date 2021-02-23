locals {
  lls_provisioning_script = "lls-provisioning.sh"
}

resource "azurerm_subnet" "lls" {
  # depends_on = [var.dc_network_depends_on]

  name                 = var.lls_subnet_name
  address_prefixes       = ["10.0.2.0/24"]
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.azurerm_virtual_network_name
}

resource "azurerm_network_interface" "lls-nic" {

  #   for_each = var.instance_count

  name                = "${var.host_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    # name                          = "lls-${each.value.index}-ipconfig"
    name                          = "lls-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.lls.id

    # Debug public ip remove if not needed
    # public_ip_address_id = azurerm_public_ip.lls-nic-public-ip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "lls-vm" {

  #   for_each = var.instance_count

  name                            = var.host_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  admin_username                  = var.admin_name
  admin_password                  = var.admin_password
  disable_password_authentication = false
  size                            = var.machine_type

  network_interface_ids = [
    # azurerm_network_interface.lls-nic[each.key].id
    azurerm_network_interface.lls-nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_8"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "lls-provisioning" {

  # TODO
  depends_on = [azurerm_linux_virtual_machine.lls-vm]

  name                 = azurerm_linux_virtual_machine.lls-vm.name
  virtual_machine_id   = azurerm_linux_virtual_machine.lls-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  protected_settings = <<SETTINGS
  {
  "script": "${base64encode(templatefile("${path.module}/${local.lls_provisioning_script}.tmpl", {
  lls_repo_url        = var.lls_repo_url,
  lls_admin_password  = var.lls_admin_password,
  lls_activation_code = var.lls_activation_code,
  lls_license_count   = var.lls_license_count,
})
)
}"
    }
  SETTINGS
}

