variable "zone_name" {
  description = "Name of the zone add to records to"
  type        = string
}

variable "rg_name" {
  description = "Name of the resource group to add the records"
  type        = string
}

variable "a-records" {
  description = "A records to attach to the domain"
  type = list(object({
    name       = string
    ttl        = optional(number)
    isAlias    = bool
    records    = optional(list(string))
    resourceID = optional(string)
  }))
  default = []
}

variable "aaaa-records" {
  description = "AAAA records to attach to the domain"
  type = list(object({
    name       = string
    ttl        = optional(number)
    isAlias    = bool
    records    = optional(list(string))
    resourceID = optional(string)
  }))
  default = []
}

variable "caa-records" {
  description = "CAA records for the domain"
  type = list(object({
    name = string
    ttl  = optional(number)
    records = list(object({
      flags = number
      tag   = string
      value = string
    }))
  }))
}

variable "cname-records" {
  description = "CNAME records for the domain"
  type = list(object({
    name       = string
    isAlias    = bool
    record     = optional(string)
    resourceID = optional(string)
    ttl        = optional(number)
  }))
  default = []
}

variable "mx-records" {
  description = "MX Records for the domain"
  type = list(object({
    name = string
    ttl  = optional(number)
    records = list(object({
      preference = number
      exchange   = string
    }))
  }))
}

variable "ptr-records" {
  description = "PTR records to attach to the domain"
  type = list(object({
    name    = string
    ttl     = optional(number)
    records = list(string)
  }))
  default = []
}

variable "srv-records" {
  description = "SRV records for the domain"
  type = list(object({
    name = string
    ttl  = optional(number)
    records = list(object({
      priority = number
      weight   = number
      port     = number
      target   = string
    }))
  }))
}

variable "txt-records" {
  description = "Text records"
  type = list(object({
    name    = string
    ttl     = optional(number)
    records = set(string)
  }))
  default = []
}

variable "ttl" {
  type    = number
  default = 3600
}

variable "tags" {
  description = "Azure Resource tags to be added to all resources"
}