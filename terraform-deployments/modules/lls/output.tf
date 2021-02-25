/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */


output "internal-ip" {
  #   value = azurerm_linux_virtual_machine.lls[*].private_ip_address
  value = azurerm_linux_virtual_machine.lls-vm.private_ip_address
}
