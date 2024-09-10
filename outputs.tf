output "privatezone-keyvault-name" {
  value = azurerm_private_dns_zone.keyvault.name
}

output "privatezone-keyvault-id" {
  value = azurerm_private_dns_zone.keyvault.id
}

output "rg-dnszones" {
  value = azurerm_resource_group.dnszones.name
}