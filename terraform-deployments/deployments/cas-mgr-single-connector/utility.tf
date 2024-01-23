/*
 * Copyright (c) 2021 Teradici Corporation
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

locals {
  resource_group_name        = var.resource_group_name != "" ? var.resource_group_name : "cas_mgr_single_connector_${random_id.string.hex}"
  cas_mgr_deployment_sa_file = "az-sa-key.json"
  default_tags               = {
    "${var.tag_name}" = "${var.tag_prefix} ${var.tag_value} ${var.tag_suffix}"
  }
}

resource "azurerm_resource_group" "main" {
  location = module.workstation-map.virtual-network-locations[0]
  name     = local.resource_group_name

  tags     = "${local.default_tags}"
}

# resource "azurerm_policy_definition" "tagging" {
#   name         = "TaggingStrategy"
#   policy_type  = "BuiltIn"
#   mode         = "Indexed"
#   display_name = "Organizational tagging policy definition"

#   metadata = <<METADATA
#     {
#       "version": "1.0.0",
#       "category": "Tags"
#     }

# METADATA

#   policy_rule = <<POLICY_RULE
#  {
#     "if": {
#         "allOf": [
#           {
#             "field": "[concat('tags[', parameters('tagName'), ']')]",
#             "notEquals": "[resourceGroup().tags[parameters('tagName')]]"
#           },
#           {
#             "value": "[resourceGroup().tags[parameters('tagName')]]",
#             "notEquals": ""
#           }
#         ]
#       },
#       "then": {
#         "effect": "modify",
#         "details": {
#           "roleDefinitionIds": [
#             "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
#           ],
#           "operations": [
#             {
#               "operation": "addOrReplace",
#               "field": "[concat('tags[', parameters('tagName'), ']')]",
#               "value": "[resourceGroup().tags[parameters('tagName')]]"
#             }
#           ]
#         }
#       }
#   }
# POLICY_RULE


#   parameters = <<PARAMETERS
#  {
#     "tagName": {
#         "type": "String",
#         "metadata": {
#           "displayName": "Tag Name",
#           "description": "Name of the tag, such as 'environment'"
#         }
#     }
#   }
# PARAMETERS

#   id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"
#   type = "Microsoft.Authorization/policyDefinitions"
#   #name = "cd3aa116-8754-49c9-a813-ad46512ece54"
# }

# data "azurerm_subscription" "primary" {}

# data "azurerm_client_config" "current" {
# }

# resource "azurerm_role_assignment" "Contributor" {
#   scope              = data.azurerm_subscription.primary.id
#   role_definition_name = "Contributor"
#   principal_id       = data.azurerm_client_config.current.object_id
# }

# resource "azurerm_resource_group_policy_assignment" "tagging" {
#   name                 = "TaggingPolicy"
#   resource_group_id    = azurerm_resource_group.main.id
#   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cd3aa116-8754-49c9-a813-ad46512ece54"

# }

resource "random_id" "string" {
  byte_length = 3
}

resource "azurerm_storage_account" "storage" {
  name                            = "winscripts${random_id.string.hex}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = true
  min_tls_version                 = "TLS1_0"
  tags                            = "${local.default_tags}"
}

resource "azurerm_storage_container" "blob" {
  name                  = azurerm_storage_account.storage.name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "private-container" {
  name                  = "privatecontainer${random_id.string.hex}"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
