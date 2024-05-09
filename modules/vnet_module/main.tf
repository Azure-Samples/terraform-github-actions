resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags = merge(
    var.vnet_tags,
    {
        environment_tag = var.environment_tag
    }
  )
}

