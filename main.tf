terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.19.0"
    }
  }
}

provider "azurerm" {
  subscription_id  = "342eadbc-a7b0-431d-b704-ea9b724c6b6f"
  client_id        = "6f467473-d68b-451c-a58b-a31326749040"
  client_secret    = "xub8Q~dOiVtl1UbLVt0LDpth5L00aC28H.8RwccU"
  tenant_id        = "92d090ef-a1e8-4979-908a-b455e09e27d3"
  features {}
}
 
# Define the existing Key Vault (Replace with your existing Key Vault details)
data "azurerm_key_vault" "example" {
  name                = "keyvaultTF"  # Replace with your Key Vault name
  resource_group_name = "terraform-rg"   # Replace with the resource group containing the Key Vault
}
 
# Reference the existing secret in the Key Vault (Replace with your secret name)
data "azurerm_key_vault_secret" "vm_password" {
  name         = "secret"  # Replace with your secret name in the Key Vault
  key_vault_id = data.azurerm_key_vault.example.id
}
 
# Reference the existing resource group
data "azurerm_resource_group" "example" {
  name = "terraform-rg"  # Replace with your existing resource group name
}
 
# Define the virtual network
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}
 
# Define the subnet
resource "azurerm_subnet" "example" {
  name                 = "subnet-example"
  resource_group_name  = data.azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}
 
# Define the Network Interface
resource "azurerm_network_interface" "example" {
  name                      = "nic-example"
  location                  = data.azurerm_resource_group.example.location
  resource_group_name       = data.azurerm_resource_group.example.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}
 
# Define the Azure Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "example" {
  name                = "vm-example"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  admin_password = data.azurerm_key_vault_secret.vm_password.value
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  tags = {
    environment = "testing"
  }
}
