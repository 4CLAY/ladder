terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.2.0"
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
  subscription_id = var.az_subscription_id
  features {}
}

# need env CLOUDFLARE_API_TOKEN
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
