terraform {
  required_version = ">= 1.5.7"
  backend "azurerm" {
    resource_group_name  = "rg1plopez-lab01"
    storage_account_name = "sta1plopez"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
 
provider "azurerm" {
  features {}
}
 
data "azurerm_client_config" "current" {}
 

module "vnet_module" {
  source              = "./modules/vnet_module"
  owner_tag = "plopez"
  vnet_address_space  = var.vnet_address_space
  environment_tag = "pRE"
  vnet_name = var.vnet_name
  resource_group_name = var.resource_group_name
  vnet_tags = var.vnet_tags

}

module "subredes" {
  source = "./modules/subredes"
  for_each = toset(["1", "2"])
  resource_group_name  = "rg1plopez-lab01"
  subnet_address_prefix = ["10.0.${each.key}.0/24"]
  vnet_name = module.vnet_module.name
  subnet_name = each.value
}

