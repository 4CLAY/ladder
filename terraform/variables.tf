variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}

variable "env_name" {
  type        = string
  description = "The name of the environment."
}

variable "cloudflare_api_token" {
  type        = string
}

variable "cloudflare_zone_name" {
  type = string
}

variable "az_subscription_id" {
  type = string
}

variable "public_key_file" {
  type        = string
  description = "The public key to be used for SSH authentication."
  default     = "~/.ssh/id_rsa.pub"
}

variable "x_ui_port" {
  type        = number
  description = "The port number for the x-ui service."
  default     = 5320
}

variable "x_ui_path" {
  type        = string
  description = "The path for the x-ui service."
  default     = "/x-ui/"
}

variable "x_ui_username" {
  type        = string
  description = "The username for the x-ui service."
}

variable "x_ui_password" {
  type        = string
  description = "The password for the x-ui service."
}