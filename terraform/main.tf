resource "random_pet" "ladder_rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "ladder_rg" {
  location = var.resource_group_location
  name     = random_pet.ladder_rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "ladder_network" {
  name                = "${var.env_name}_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ladder_rg.location
  resource_group_name = azurerm_resource_group.ladder_rg.name
}

# Create subnet
resource "azurerm_subnet" "ladder_subnet" {
  name                 = "${var.env_name}_subnet"
  resource_group_name  = azurerm_resource_group.ladder_rg.name
  virtual_network_name = azurerm_virtual_network.ladder_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "ladder_public_ip" {
  name                = "${var.env_name}_public_ip"
  location            = azurerm_resource_group.ladder_rg.location
  resource_group_name = azurerm_resource_group.ladder_rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ladder_nsg" {
  name                = "${var.env_name}_network_security_group"
  location            = azurerm_resource_group.ladder_rg.location
  resource_group_name = azurerm_resource_group.ladder_rg.name

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
  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "X_UI"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.x_ui_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "ladder_nic" {
  name                = "${var.env_name}_NIC"
  location            = azurerm_resource_group.ladder_rg.location
  resource_group_name = azurerm_resource_group.ladder_rg.name

  ip_configuration {
    name                          = "${var.env_name}_nic_configuration"
    subnet_id                     = azurerm_subnet.ladder_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ladder_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "ladder_nsg_association" {
  network_interface_id      = azurerm_network_interface.ladder_nic.id
  network_security_group_id = azurerm_network_security_group.ladder_nsg.id
}

data "cloudflare_zone" "zone" {
  name = var.cloudflare_zone_name
}

resource "cloudflare_record" "cf_record" {
  zone_id         = data.cloudflare_zone.zone.id
  name            = local.record_name
  content         = azurerm_linux_virtual_machine.ladder_vm.public_ip_address
  type            = "A"
  ttl             = 3600
  allow_overwrite = true
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "ladder_vm" {
  name                  = "${var.env_name}_VM"
  location              = azurerm_resource_group.ladder_rg.location
  resource_group_name   = azurerm_resource_group.ladder_rg.name
  network_interface_ids = [azurerm_network_interface.ladder_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "ladderOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name  = "${var.env_name}Host"
  admin_username = var.username

  admin_ssh_key {
    username   = var.username
    public_key = file("${var.public_key_file}")
  }

  user_data = base64encode(templatefile("${path.module}/userdata.yaml", {
    host: local.hostname,
    x_ui_port: var.x_ui_port,
    x_ui_path: var.x_ui_path,
    x_ui_username: var.x_ui_username,
    x_ui_password: var.x_ui_password
  }))
}

locals {
  record_name = "${var.env_name}-proxy"
  hostname = "${local.record_name}.${var.cloudflare_zone_name}"
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new environment is created
    resource_group = var.env_name
  }
  byte_length = 5
}

resource "azurerm_storage_account" "ladder_sa" {
  name                     = "${var.env_name}sa${random_id.random_id.hex}"
  resource_group_name      = azurerm_resource_group.ladder_rg.name
  location                 = azurerm_resource_group.ladder_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
}

resource "azurerm_storage_container" "ladder_container" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.ladder_sa.name
  container_access_type = "container"
}

resource "azurerm_storage_blob" "clash" {
  name                   = "clash.yaml"
  storage_account_name   = azurerm_storage_account.ladder_sa.name
  storage_container_name = azurerm_storage_container.ladder_container.name
  type                   = "Block"
  source_content         = templatefile("${path.module}/clash.yaml", 
    {
      host = local.hostname,
    }
  )
}