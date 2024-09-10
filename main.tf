terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "terraformrg"
    storage_account_name = "terraformstoragefe832e63"
    container_name       = "terraform"
    key                  = "tf-github-actions.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

locals {
  tags = {
    source  = "terraform"
    managed = "as-code"
  }
  permitted_ips = [
    "62.3.75.22",
    "4.213.28.114",
    "4.213.28.115",
    "4.213.81.64/29",
    "4.232.98.120/29",
    "13.73.248.16/29",
    "20.17.126.64/29",
    "20.21.37.40/29",
    "20.36.120.104/29",
    "20.37.64.104/29",
    "20.37.156.120/29",
    "20.37.195.0/29",
    "20.37.224.104/29",
    "20.38.84.72/29",
    "20.38.136.104/29",
    "20.39.11.8/29",
    "20.41.4.88/29",
    "20.41.64.120/29",
    "20.41.192.104/29",
    "20.42.4.120/29",
    "20.42.129.152/29",
    "20.42.224.104/29",
    "20.43.41.136/29",
    "20.43.65.128/29",
    "20.43.130.80/29",
    "20.45.112.104/29",
    "20.45.192.104/29",
    "20.59.103.64/29",
    "20.72.18.248/29",
    "20.79.107.152/29",
    "20.88.157.176/29",
    "20.90.132.152/29",
    "20.113.254.88/29",
    "20.115.247.64/29",
    "20.118.195.128/29",
    "20.119.155.128/29",
    "20.150.160.96/29",
    "20.189.106.112/29",
    "20.192.161.104/29",
    "20.192.225.48/29",
    "20.210.70.64/30",
    "20.215.4.240/29",
    "20.217.44.240/29",
    "40.67.48.104/29",
    "40.74.30.72/29",
    "40.80.56.104/29",
    "40.80.168.104/29",
    "40.80.184.120/29",
    "40.82.248.248/29",
    "40.89.16.104/29",
    "51.12.41.8/29",
    "51.12.193.8/29",
    "51.53.30.144/29",
    "51.104.25.128/29",
    "51.105.80.104/29",
    "51.105.88.104/29",
    "51.107.48.104/29",
    "51.107.144.104/29",
    "51.120.40.104/29",
    "51.120.224.104/29",
    "51.137.160.112/29",
    "51.143.192.104/29",
    "52.136.48.104/29",
    "52.140.104.104/29",
    "52.150.136.120/29",
    "52.159.71.160/29",
    "52.228.80.120/29",
    "68.210.172.176/29",
    "68.221.93.128/29",
    "69.15.0.0/16",
    "102.133.56.88/29",
    "102.133.216.88/29",
    "147.243.0.0/16",
    "157.55.93.2",
    "157.55.93.3",
    "158.23.108.56/29",
    "172.204.165.112/29",
    "172.207.68.70",
    "172.207.68.71",
    "172.207.69.80/30",
    "191.233.9.120/29",
    "191.235.225.128/29"
  ]
}

resource "azurerm_resource_group" "dnszones" {
  name     = "rg-whitefam-dnszones"
  location = "UK South"
  tags     = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group" "cdnprofiles" {
  name     = "rg-whitefam-cdnprofiles"
  location = "UK South"
  tags     = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_profile" "cdn-mta-sts" {
  name                = "cdn-mjwmtasts"
  location            = "global"
  resource_group_name = azurerm_resource_group.cdnprofiles.name
  sku                 = "Standard_Microsoft"
  tags                = local.tags
}
