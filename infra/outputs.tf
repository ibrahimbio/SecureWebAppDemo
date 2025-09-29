output "webapp_url" {
  description = "The default hostname of the web app"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "staging_slot_url" {
  description = "The default hostname of the staging slot"  
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}
