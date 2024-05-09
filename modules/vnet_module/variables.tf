variable "resource_group_name" {
  description = "Nombre del Resource Group existente en Azure"
  type        = string
  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "The resource group name must not be empty."
  }
}

variable "vnet_name" {

  description = "Nombre de la VNet"
  type        = string
  validation {
    condition     = length(var.vnet_name) > 0 && can(regex("^vnet[a-z]{2,}tfexercise\\d{2,}$", var.vnet_name))
    error_message = "vnet_name no puede estar vacío debe comenzar con 'vnet', seguido de al menos dos caracteres en el rango [a-z], seguido de 'tfexercise', y terminar con al menos dos dígitos numéricos."
  }
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la Virtual Network"
  type        = list(string)
  validation {
    condition     = can(cidrsubnet(element(var.vnet_address_space, 0), 0, 0))
    error_message = "The VNet address space must be a valid CIDR block."
  }
}

variable "location" {
  description = "Ubicación donde se desplegará la VNet"
  default     = "West Europe"
}

variable "owner_tag" {
  description = "Propietario de la VNet"
  type        = string
  validation {
    condition = length(var.owner_tag) > 0
    error_message = "El propietario de la VNet no puede estar vacío"
  
  }
}

variable "allowed_tags" {
  default = ["dev", "pro", "tes", "pre"]
}

variable "environment_tag" {
  description = "Entorno de la VNet (dev, test, prod, pre)"
  type        = string
  validation {
    condition     = length(var.environment_tag) > 0 && contains(["dev", "pro", "tes", "pre"], lower(var.environment_tag))
    error_message = "environment_tag no puede ser una cadena vacía y debe ser 'dev', 'pro', 'tes' o 'pre' (mayúsculas o minúsculas)"
  }
}

variable "vnet_tags" {
  description = "Tags adicionales para la VNet"
  type        = map(string)
  default     = {}
  validation {
    condition = can(var.vnet_tags) && length(keys(var.vnet_tags)) > 0 && alltrue([for k, v in var.vnet_tags : length(k) > 0 && length(v) > 0])
    error_message = "vnet_tags no puede ser nulo y ninguno de los valores del mapa puede ser una cadena vacía"
  }
}



