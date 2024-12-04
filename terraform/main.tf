terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  required_version= ">=1.1.0"
}

provider "azurerm"{
    features {}
}

variable "vm_count"{
    default= 3
}

resource "azurerm_virtual_network" "vnet"{
    name= "vnet"
    address_space= ["10.0.0.0/16"]
    location= "centralindia"
    resource_group_name= "wth"
}

resource "azurerm_subnet" "vsubnet"{
    name= "vsubnet" 
    resource_group_name= "wth"
    virtual_network_name= azurerm_virtual_network.vnet.name 
    address_prefixes= ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pub_ip"{
    count= var.vm_count 
    name= "Pubip-${count.index+ 1}"
    resource_group_name= "wth" 
    location= "centralindia"
    allocation_method= "Dynamic"
    sku= "Basic"
}

resource "azurerm_network_interface" "main"{
    count= var.vm_count
    name= "vnet-nic-${count.index+ 1}" 
    location= "centralindia"
    resource_group_name= "wth" 

    ip_configuration{
        name= "test1"
        subnet_id= azurerm_subnet.vsubnet.id 
        private_ip_address_allocation= "Dynamic"
        public_ip_address_id= azurerm_public_ip.pub_ip[count.index].id 
    }
}

data "azurerm_ssh_public_key" "ssh_key"{
    name= "vm-key"
    resource_group_name= "wth"
}

resource "azurerm_linux_virtual_machine" "vm"{
    count= var.vm_count
    name= "vm-${count.index+ 1}"
    location= "centralindia" 
    resource_group_name= "wth" 
    network_interface_ids= [azurerm_network_interface.main[count.index].id]
    size= "Standard_B1s"
    admin_username= "azureuser" 
    admin_ssh_key {
        username = "azureuser" 
        public_key= data.azurerm_ssh_public_key.ssh_key.public_key
    }
    os_disk{
        caching= "ReadWrite"
        storage_account_type= "Standard_LRS"
        disk_size_gb=30
    }
    source_image_reference{
        publisher= "Canonical"
        offer= "0001-com-ubuntu-server-jammy"
        sku= "22_04-lts"
        version= "latest"
    }
}

output "vm_public_ip"{
    value= azurerm_linux_virtual_machine.vm[0].public_ip_addresses
}
