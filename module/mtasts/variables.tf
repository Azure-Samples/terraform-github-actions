variable "location" {
  type    = string
  default = "uksouth"
}

variable "domain-name" {
  type        = string
  description = "The domain MTA-STS/TLS-RPT is being deployed for."
}

variable "mtastsmode" {
  type        = string
  default     = "testing"
  description = "MTA-STS policy 'mode'. Either 'testing' or 'enforce'."
}

variable "max-age" {
  type        = string
  default     = "86400"
  description = "MTA-STS max_age. Time in seconds the policy should be cached. Default is 1 day"
}

variable "mx-records" {
  type        = list(string)
  description = "list of 'mx' records that should be included in mta-sts policy"
}

variable "reporting-email" {
  type        = string
  default     = "tls-rpt"
  description = "(Optional) Email to use for TLS-RPT reporting."
}

variable "dns-resource-group" {
  type        = string
  description = "resource group that contains existing resources"
}

variable "cdn-resource-group" {
  type        = string
  description = "resource group that contains existing resources"
}

variable "stg-resource-group" {
  type        = string
  description = "resource group thta contains existing resources"
}

variable "use-existing-cdn-profile" {
  type        = bool
  description = "true: have the module create a cdn profile per domain, false: supply one as a variable"
}

variable "existing-cdn-profile" {
  type        = string
  description = "CDN Profile to use if use-existing-cdn-profile is true"
}
variable "resource-prefix" {
  type        = string
  description = "Prefix to use on resources"

}
variable "tags" {
  description = "Azure Resource tags to be added to all resources"
}

variable "permitted-ips" {
  description = "list of IP addresses that can access storage accounts"
  sensitive   = false
  type        = list(string)
}
