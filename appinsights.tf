resource "azurerm_application_insights" "appi" {
  name                = var.appi_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-aks.name
  //workspace_id        = data.azurerm_log_analytics_workspace.la_frmd.id
  application_type = "web"
}
