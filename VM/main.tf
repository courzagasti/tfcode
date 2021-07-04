terraform {
  backend "azurerm" {
    resource_group_name   = "tf-rg"
    storage_account_name  = "tfsta1000"
    container_name        = "tfstate"
    key                   = "FeL3Ec+Q6Y71kP59UzowImCTYppFoCYJosfcLpdpByIbMhEfoXhNgHxj2+79LfGu6P0SlzP0xfQ+vJkc4TbMyw=="
}

  required_providers {
    azurerm = "v2.66.0"
  }
}
provider "azurerm" {
  features {
      key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - infra-RG deploying with Terraform
resource "azurerm_resource_group" "rg" {
  name     = "app-rg"
  location = "East US 2"
}
# Create our Virtual Network - TF-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "appvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VMAPP"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - appsa
resource "azurerm_storage_account" "sa" {
  name                     = "satf1000"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "demoenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "vm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - DEMO-VM01
resource "azurerm_virtual_machine" "vm01" {
  name                  = "vm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "vm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "vm01"
    admin_username     = "winusr"
    admin_password     = "Password123$"
  }
  os_profile_windows_config {
  }
}
