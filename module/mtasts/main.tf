locals {
  tls_rpt_email  = length(split("@", var.reporting-email)) == 2 ? var.reporting-email : "${var.reporting-email}@${var.domain-name}"
  policyhash     = md5("${var.mtastsmode},${join(",", var.mx-records)}")
  cdn-prefix     = "cdn${var.resource-prefix}mtasts"
  storage_prefix = coalesce(var.resource-prefix, substr(replace(local.cdn-prefix, "-", ""), 0, 16))
}

resource "azurerm_storage_account" "stmtasts" {
  name                            = "st${local.storage_prefix}mtasts"
  resource_group_name             = var.stg-resource-group
  location                        = var.location
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  min_tls_version                 = "TLS1_2"
  account_kind                    = "StorageV2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                            = var.tags
  static_website {
    index_document     = "index.htm"
    error_404_document = "error.htm"
  }
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = var.permitted-ips
  }
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_blob" "mta-sts" {
  name                   = ".well-known/mta-sts.txt"
  storage_account_name   = azurerm_storage_account.stmtasts.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/plain"
  source_content         = <<EOF
version: STSv1
mode: ${var.mtastsmode}
${join("", formatlist("mx: %s\n", var.mx-records))}max_age: ${var.max-age}
  EOF
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.htm"
  storage_account_name   = azurerm_storage_account.stmtasts.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "<html><head><title>Nothing to see</title></head><body><center><h1>Nothing to see</h1></center></body></html>"
}

resource "azurerm_storage_blob" "error" {
  name                   = "error.htm"
  storage_account_name   = azurerm_storage_account.stmtasts.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "<html><head><title>Error Page</title></head><body><center><h1>Nothing to see</h1></center></body></html>"
}

resource "azurerm_cdn_profile" "cdnmtasts" {
  count               = var.use-existing-cdn-profile ? 0 : 1
  name                = "cdn-${local.cdn-prefix}"
  location            = "global"
  resource_group_name = var.cdn-resource-group
  sku                 = "Standard_Microsoft"
  tags                = var.tags
}

resource "azurerm_cdn_endpoint" "mtastsendpoint" {
  name                = local.cdn-prefix
  profile_name        = var.use-existing-cdn-profile ? var.existing-cdn-profile : azurerm_cdn_profile.cdnmtasts[0].name
  location            = "global"
  resource_group_name = var.cdn-resource-group
  tags                = var.tags
  is_http_allowed     = false

  origin {
    name      = "mtasts-endpoint"
    host_name = azurerm_storage_account.stmtasts.primary_web_host
  }

  origin_host_header = azurerm_storage_account.stmtasts.primary_web_host

  delivery_rule {
    name  = "EnforceHTTPS"
    order = "1"

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "mtastscustomdomain" {
  name            = local.cdn-prefix
  cdn_endpoint_id = azurerm_cdn_endpoint.mtastsendpoint.id
  host_name       = "${azurerm_dns_cname_record.mta-sts.name}.${azurerm_dns_cname_record.mta-sts.zone_name}"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
  depends_on = [azurerm_dns_cname_record.mta-sts, azurerm_dns_cname_record.cdnverify]
}

resource "azurerm_dns_cname_record" "mta-sts" {
  name                = "mta-sts"
  zone_name           = var.domain-name
  resource_group_name = var.dns-resource-group
  ttl                 = 300
  target_resource_id  = azurerm_cdn_endpoint.mtastsendpoint.id
  tags                = var.tags
}

resource "azurerm_dns_cname_record" "cdnverify" {
  name                = "cdnverify.${azurerm_dns_cname_record.mta-sts.name}"
  zone_name           = var.domain-name
  resource_group_name = var.dns-resource-group
  ttl                 = 300
  record              = "cdnverify.${azurerm_cdn_endpoint.mtastsendpoint.name}.azureedge.net"
  tags                = var.tags
}

resource "azurerm_dns_txt_record" "mta-sts" {
  name                = "_mta-sts"
  zone_name           = var.domain-name
  resource_group_name = var.dns-resource-group
  ttl                 = 300
  tags                = var.tags

  record {
    value = "v=STSv1; id=${local.policyhash}"
  }
}

resource "azurerm_dns_txt_record" "smtp-tls" {
  name                = "_smtp._tls"
  zone_name           = var.domain-name
  resource_group_name = var.dns-resource-group
  ttl                 = 300
  tags                = var.tags

  record {
    value = "v=TLSRPTv1; rua=mailto:${local.tls_rpt_email}"
  }
}
