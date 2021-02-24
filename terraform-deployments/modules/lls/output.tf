output "internal-ip" {
  #   value = azurerm_linux_virtual_machine.lls[*].private_ip_address
  value = azurerm_linux_virtual_machine.lls-vm.private_ip_address
}
