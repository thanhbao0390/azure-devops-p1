output "azapp1_public_ip" {
    value = azurerm_public_ip.azapp1.fqdn
}

output "jumpbox_public_ip" {
    value = azurerm_public_ip.jumpbox.fqdn
}