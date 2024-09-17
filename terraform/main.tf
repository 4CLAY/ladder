resource "random_pet" "labber_rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "labber_rg" {
  location = var.resource_group_location
  name     = random_pet.labber_rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "labber_network" {
  name                = "labber_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.labber_rg.location
  resource_group_name = azurerm_resource_group.labber_rg.name
}

# Create subnet
resource "azurerm_subnet" "labber_subnet" {
  name                 = "labber_subnet"
  resource_group_name  = azurerm_resource_group.labber_rg.name
  virtual_network_name = azurerm_virtual_network.labber_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "labber_public_ip" {
  name                = "labber_public_ip"
  location            = azurerm_resource_group.labber_rg.location
  resource_group_name = azurerm_resource_group.labber_rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "labber_nsg" {
  name                = "labber_network_security_group"
  location            = azurerm_resource_group.labber_rg.location
  resource_group_name = azurerm_resource_group.labber_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "labber_nic" {
  name                = "labber_NIC"
  location            = azurerm_resource_group.labber_rg.location
  resource_group_name = azurerm_resource_group.labber_rg.name

  ip_configuration {
    name                          = "labber_nic_configuration"
    subnet_id                     = azurerm_subnet.labber_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.labber_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "labber_nsg_association" {
  network_interface_id      = azurerm_network_interface.labber_nic.id
  network_security_group_id = azurerm_network_security_group.labber_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.labber_rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.labber_rg.location
  resource_group_name      = azurerm_resource_group.labber_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# resource "cloudflare_record" "cf_record" {
#   zone_id = var.cloudflare_zone_id
#   name    = "labber"
#   content = azurerm_public_ip.labber_public_ip.ip_address
#   type    = "A"
#   ttl     = 3600
#   allow_overwrite = true
# }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "labber_vm" {
  name                  = "labberVM"
  location              = azurerm_resource_group.labber_rg.location
  resource_group_name   = azurerm_resource_group.labber_rg.name
  network_interface_ids = [azurerm_network_interface.labber_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "labberOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "labberHost"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(file("${path.module}/userdata.sh"))
}