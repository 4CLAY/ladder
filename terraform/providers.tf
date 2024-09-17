terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "4.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# # need env CLOUDFLARE_API_TOKEN
# provider "cloudflare" {
# }
