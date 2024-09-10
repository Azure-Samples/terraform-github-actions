resource "azurerm_dns_zone" "tftest-mjw" {
  name                = "tfttest.matthewjwhite.co.uk"
  resource_group_name = azurerm_resource_group.dnszones.name
  lifecycle {
    prevent_destroy = true
  }
  tags = local.tags
}

module "bs-co-records" {
  source    = "./module/dnsrecords"
  zone_name = azurerm_dns_zone.tftest-mjw.name
  rg_name   = azurerm_resource_group.dnszones.name
  tags      = local.tags
  a-records = [
    {
      name = "@",
      records = [
        "198.185.159.144",
        "198.185.159.145",
        "198.49.23.144",
        "198.49.23.145"
      ],
      isAlias = false
    }
  ]
  aaaa-records = []
  caa-records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        {
          flags = 0
          tag   = "issue"
          value = "digicert.com"
        },
        {
          flags = 0
          tag   = "issue"
          value = "letsencrypt.org"
        },
        {
          flags = 0
          tag   = "iodef"
          value = "mailto:dnscaa@matthewjwhite.co.uk"
        }
      ]
    }
  ]
  cname-records = [
    {
      name    = "autodiscover",
      record  = "autodiscover.outlook.com",
      isAlias = false
    },
    {
      name    = "enterpriseenrollment",
      record  = "enterpriseenrollment.manage.microsoft.com",
      isAlias = false
    },
    {
      name    = "enterpriseregistration",
      record  = "enterpriseregistration.windows.net",
      isAlias = false
    },
    {
      name    = "nhty6l3pj4xw4kj6tybz",
      record  = "verify.squarespace.com",
      isAlias = false
    },
    {
      name    = "selector1._domainkey",
      record  = "selector1-tftest-mjw._domainkey.objectatelier.onmicrosoft.com",
      isAlias = false
    },
    {
      name    = "selector2._domainkey",
      record  = "selector2-tftest-mjw._domainkey.objectatelier.onmicrosoft.com",
      isAlias = false
    },
    {
      name    = "www",
      record  = "ext-cust.squarespace.com",
      isAlias = false
    }
  ]
  mx-records = [
    {
      name = "@"
      ttl  = 3600
      records = [
        {
          preference = 0
          exchange   = "tftest-mjw.mail.protection.outlook.com"
        }
      ]
    }
  ]
  ptr-records = []
  srv-records = []
  txt-records = [
    {
      name = "@",
      records = [
        "MS=ms59722365",
        "v=spf1 include:spf.protection.outlook.com -all"
      ]
    }

  ]
}

/*
module "tftest-mjw-mtasts" {
  source                   = "./module/mtasts"
  use-existing-cdn-profile = true
  existing-cdn-profile     = azurerm_cdn_profile.cdn-mta-sts.name
  cdn-resource-group       = azurerm_resource_group.cdnprofiles.name
  dns-resource-group       = azurerm_resource_group.dnszones.name
  mx-records               = ["tftest-mjw.mail.protection.outlook.com"]
  domain-name              = azurerm_dns_zone.tftest-mjw.name
  depends_on               = [azurerm_resource_group.cdnprofiles, azurerm_resource_group.dnszones]
  reporting-email          = "tls-reports@matthewjwhite.co.uk"
  stg-resource-group       = "RG-WhiteFam-UKS"
  resource-prefix          = "bsco"
  tags                     = local.tags
  permitted-ips            = local.permitted_ips
}
*/