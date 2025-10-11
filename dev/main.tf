resource "azurerm_resource_group" "this" {
  name     = "finopay-dev"
  location = "East US 2"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.0"
}

##################
# Locals
##################

locals {
  security_rules = {
    "web_allow_lb_probe" = {
      nsg_name                   = "web_tier"
      name                       = "AllowAzureLBProbe"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }

    "web_allow_http" = {
      nsg_name                   = "web_tier"
      name                       = "AllowHTTPInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }

    "web_allow_https" = {
      nsg_name                   = "web_tier"
      name                       = "AllowHTTPSInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }

    "db_allow_sql_from_web" = {
      nsg_name                   = "database_tier"
      name                       = "AllowSQLFromWeb"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.1.0/24"
      destination_address_prefix = "*"
    }
  }

  nsg_map = {
    web_tier      = azurerm_network_security_group.web_tier
    database_tier = azurerm_network_security_group.database_tier
  }
}

##################
# Networking
##################

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.14.0"

  parent_id = azurerm_resource_group.this.id
  location  = azurerm_resource_group.this.location
  name      = "vnet-finopay-dev-${azurerm_resource_group.this.location}-001"

  address_space = ["10.0.0.0/16"]

  subnets = {
    web_tier = {
      name             = "web"
      address_prefixes = ["10.0.1.0/24"]
      network_security_group = {
        id = azurerm_network_security_group.web_tier.id
      }
    }
    database_tier = {
      name             = "database"
      address_prefixes = ["10.0.2.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.this.id
      }
      network_security_group = {
        id = azurerm_network_security_group.database_tier.id
      }
    }
  }

}

# Network Security Groups

resource "azurerm_network_security_group" "web_tier" {
  name                = "nsg-web-finopay-dev-001"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "database_tier" {
  name                = "nsg-db-finopay-dev-001"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.security_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = local.nsg_map[each.value.nsg_name].name
}


# Network Extras

resource "azurerm_nat_gateway" "this" {
  name                = "nat-finopay-dev-001"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "pip-nat-finopay-dev-001"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

#######################
# Azure Load Balancer
#######################
module "loadbalancer" {
  source  = "Azure/loadbalancer/azurerm"
  version = "~> 4.0"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "finopay-dev-lb-002"
  type                = "public"
  lb_sku              = "Standard"
  pip_sku             = "Standard"

  frontend_name = "frontend-finopay"
  pip_name      = "pip-lb-finopay-dev-001"

  remote_port = {
    http = ["Tcp", "80"]
  }

  lb_port = {
    http  = ["80", "Tcp", "80"]
    https = ["443", "Tcp", "443"]
  }

  lb_probe = {
    http  = ["Tcp", "80", ""]
    https = ["Tcp", "443", ""]
  }
}

