output "resource_group_name" {
  value = azurerm_resource_group.ladder_rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.ladder_vm.public_ip_address
}

output "node_enpoint" {
  value = "https://${local.hostname}:${var.x_ui_port}/${var.x_ui_path}/"
}

output "clash_subscription_url" {
  value = azurerm_storage_blob.clash.url
}