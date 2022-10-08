provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "azapp1" {
  name     = "${var.prefix}-resource-group"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "azapp1" {
  name                = "${var.prefix}-azapp1-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name
  tags                = var.tags
}

resource "azurerm_subnet" "azapp1" {
  name                 = "${var.prefix}-azapp1-subnet"
  resource_group_name  = azurerm_resource_group.azapp1.name
  virtual_network_name = azurerm_virtual_network.azapp1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "azapp1" {
  name                = "${var.prefix}-azapp1-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name
  allocation_method   = "Static"
  domain_name_label   = azurerm_resource_group.azapp1.name
  tags                = var.tags
}

resource "azurerm_lb" "azapp1" {
  name                = "${var.prefix}-azapp1-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.azapp1.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id     = azurerm_lb.azapp1.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "azapp1" {
  resource_group_name = azurerm_resource_group.azapp1.name
  loadbalancer_id     = azurerm_lb.azapp1.id
  name                = "ssh-running-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = azurerm_resource_group.azapp1.name
  loadbalancer_id                = azurerm_lb.azapp1.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bpepool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.azapp1.id
}

data "azurerm_resource_group" "packer_rg" {
  name = var.packer_resource_group
}

data "azurerm_image" "packer_image" {
  name                = var.packer_image_name
  resource_group_name = data.azurerm_resource_group.packer_rg.name
}

resource "azurerm_virtual_machine_scale_set" "azapp1" {
  name                = "${var.prefix}-vm-scale-set"
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_B1s"
    tier     = "Standard"
    capacity = var.instance_count
  }

  storage_profile_image_reference {
    id = data.azurerm_image.packer_image.id
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun            = 0
    caching        = "ReadWrite"
    create_option  = "Empty"
    disk_size_gb   = 10
  }

  os_profile {
    computer_name_prefix = "${var.prefix}-vm"
    admin_username       = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  network_profile {
    name    = "TerraformNetworkProfile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = azurerm_subnet.azapp1.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      primary                                = true
    }
  }
  
  tags = var.tags
}

resource "azurerm_public_ip" "jumpbox" {
  name                = "${var.prefix}-jumpbox-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name
  allocation_method   = "Static"
  domain_name_label   = "${azurerm_resource_group.azapp1.name}-ssh"
  tags                = var.tags
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "${var.prefix}-jumpbox-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.azapp1.name

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = azurerm_subnet.azapp1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }

  tags = var.tags
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "${var.prefix}-jumpbox"
  location              = var.location
  resource_group_name   = azurerm_resource_group.azapp1.name
  network_interface_ids = [azurerm_network_interface.jumpbox.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = var.tags
}