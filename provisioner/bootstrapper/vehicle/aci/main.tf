terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" { type = string }
variable "rg" { type = string }
variable "uami_id" { type = string }
variable "image" { type = string }
variable "cluster" { type = string }

# Run-once ACI (restart Never) for the azure-dr vehicle; UAMI -> AKV. Self-deletes via terraform destroy.
resource "azurerm_container_group" "bootstrapper" {
  name                = "pn-bootstrapper"
  location            = var.location
  resource_group_name = var.rg
  os_type             = "Linux"
  ip_address_type     = "None"
  restart_policy      = "Never"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.uami_id]
  }

  container {
    name   = "bootstrap"
    image  = var.image
    cpu    = "1"
    memory = "2"
    environment_variables = {
      CLUSTER = var.cluster
    }
  }
}
