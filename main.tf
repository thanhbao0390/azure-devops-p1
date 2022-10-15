provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

locals {
  instance_count = var.instance_count
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "main"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count               = local.instance_count
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_nat_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = "${var.port_web}"
  backend_port                   = "${var.port_web}"
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-backend-address-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = local.instance_count
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
  ip_configuration_name   = "primary"
}

resource "azurerm_network_security_group" "webserver" {
  name                = "tls_webserver"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls-Inbound"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "${var.port_web}"
    destination_address_prefix = "*"
  }
  security_rule {
    access                     = "Allow"
    direction                  = "Outbound"
    name                       = "tls-Outbound"
    priority                   = 101
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "${var.port_web}"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.webserver.id
}

resource "azurerm_availability_set" "main" {
  name                         = "${var.prefix}avset"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_linux_virtual_machine" "main" {
  count                           = local.instance_count
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.admin_username}"
  admin_password                  = "${var.admin_password}"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  availability_set_id             = azurerm_availability_set.main.id
  source_image_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.packer_resource_group}/providers/Microsoft.Compute/images/${var.packer_image_name}"

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

}

resource "azurerm_managed_disk" "main" {
  count                = local.instance_count
  name                 = "${var.prefix}-managed_disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = local.instance_count
  managed_disk_id    = azurerm_managed_disk.main[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = 10*count.index
  caching            = "ReadWrite"
}