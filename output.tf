output "azurerm_public_ip" {
    value = azurerm_public_ip.main.fqdn
}

output "azurerm_public_ip_id" {
    value = azurerm_public_ip.main.id
}
