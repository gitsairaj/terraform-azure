terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "sairaj-rg" {
  name     = "sairaj-resources"
  location = "Central India"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "sairaj-vn" {
  name                = "sairaj-network"
  resource_group_name = azurerm_resource_group.sairaj-rg.name
  location            = azurerm_resource_group.sairaj-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "sairaj-subnet" {
  name                 = "sairaj-subnet"
  resource_group_name  = azurerm_resource_group.sairaj-rg.name
  virtual_network_name = azurerm_virtual_network.sairaj-vn.name
  address_prefixes     = ["10.123.1.0/24"]

}

resource "azurerm_network_security_group" "sairaj-nsg" {
  name                = "sairaj-sg"
  location            = azurerm_resource_group.sairaj-rg.location
  resource_group_name = azurerm_resource_group.sairaj-rg.name
  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "sairaj-dev-rule" {

  name                        = "sairaj-dev1-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "115.124.115.69"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.sairaj-rg.name
  network_security_group_name = azurerm_network_security_group.sairaj-nsg.name
}

resource "azurerm_subnet_network_security_group_association" "sairaj-sga" {
  subnet_id                 = azurerm_subnet.sairaj-subnet.id
  network_security_group_id = azurerm_network_security_group.sairaj-nsg.id
}

resource "azurerm_public_ip" "sairaj-pip" {
  name                = "sairaj-ip"
  resource_group_name = azurerm_resource_group.sairaj-rg.name
  location            = azurerm_resource_group.sairaj-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "sairaj-nic" {
  name                = "sairaj-nic1"
  location            = azurerm_resource_group.sairaj-rg.location
  resource_group_name = azurerm_resource_group.sairaj-rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sairaj-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sairaj-pip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "sairaj-linux-vm" {
  name                  = "Linux-vm-1"
  resource_group_name   = azurerm_resource_group.sairaj-rg.name
  location              = azurerm_resource_group.sairaj-rg.location
  size                  = "Standard_B1s"
  admin_username        = "testuser"
  network_interface_ids = [azurerm_network_interface.sairaj-nic.id]

  custom_data = filebase64("customdata.tpl")

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username = "testuser"
    #public_key = file("path of the pub file")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", {
      hostname     = self.public_ip_address,
      user         = "testuser",
      #identityfile = "path"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }


  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "sairaj-ip-data" {
  name                = azurerm_public_ip.sairaj-pip.name
  resource_group_name = azurerm_resource_group.sairaj-rg.name
}

output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.sairaj-linux-vm.name}: ${data.azurerm_public_ip.sairaj-ip-data.ip_address}"
}
