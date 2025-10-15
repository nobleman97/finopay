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

  product     = "finopay"
  environment = "dev"

  common_tags = {
    project     = "finopay"
    environment = "dev"
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
  name      = "${local.product}-${local.environment}-${azurerm_resource_group.this.location}-${module.naming.virtual_network.name}"

  address_space = var.vnet_address_space

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
    appgw_tier = {
      name             = "appgw"
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

# Network Security Groups

resource "azurerm_network_security_group" "web_tier" {
  name                = "web-${local.product}-${local.environment}-${module.naming.network_security_group.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_group" "database_tier" {
  name                = "database-${local.product}-${local.environment}-${module.naming.network_security_group.name}"
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
  name                = "${module.vnet.name}-${module.naming.nat_gateway.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = var.nat_gateway_sku
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "${azurerm_nat_gateway.this.name}-${module.naming.public_ip.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
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

  for_each = var.load_balancers

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${local.product}-${local.environment}-${module.naming.lb.name}"
  type                = each.value.type
  lb_sku              = each.value.sku
  pip_sku             = var.public_ip_sku

  frontend_name = each.value.frontend_name
  pip_name      = "${local.product}-${local.environment}-${module.naming.lb.name}-${module.naming.public_ip.name}"

  remote_port = each.value.remote_port
  lb_port     = each.value.lb_ports
  lb_probe    = each.value.lb_probes

  depends_on = [azurerm_resource_group.this]
}

#######################
# Availability Set
#######################
resource "azurerm_availability_set" "web_tier" {
  name                         = "${local.product}-${local.environment}-web-${module.naming.availability_set.name_unique}"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  platform_fault_domain_count  = var.availability_set.platform_fault_domain_count
  platform_update_domain_count = var.availability_set.platform_update_domain_count
  managed                      = var.availability_set.managed

  tags = var.availability_set.tags
}

#######################
# Azure Key Vault
#######################
resource "azurerm_key_vault" "this" {
  name                            = var.key_vault_config.name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.key_vault_config.sku_name
  enabled_for_disk_encryption     = var.key_vault_config.enabled_for_disk_encryption
  enabled_for_deployment          = var.key_vault_config.enabled_for_deployment
  enabled_for_template_deployment = var.key_vault_config.enabled_for_template_deployment
  soft_delete_retention_days      = var.key_vault_config.soft_delete_retention_days
  purge_protection_enabled        = var.key_vault_config.purge_protection_enabled
  rbac_authorization_enabled      = var.key_vault_config.enable_rbac_authorization

  tags = var.key_vault_config.tags
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

#####################################
# Generate random passwords for VMs
#####################################
resource "random_password" "vmss_admin" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "db_admin" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "admin_username" {
  name         = "vm-admin-username"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "vmss_admin_password" {
  name         = "vmss-admin-password"
  value        = random_password.vmss_admin.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  name         = "db-admin-password"
  value        = random_password.db_admin.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# #######################
# # Web Tier VMSS
# #######################

resource "azurerm_windows_virtual_machine_scale_set" "web_tier" {
  name                = "${local.environment}-web"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  upgrade_mode        = "Manual"

  sku            = var.vmss_config.vm_size
  instances      = var.vmss_config.initial_instance_count
  admin_username = var.admin_username
  admin_password = data.azurerm_key_vault_secret.secrets["vmss-admin-password"].value

  source_image_reference {
    publisher = var.vmss_config.source_image_reference.publisher
    offer     = var.vmss_config.source_image_reference.offer
    sku       = var.vmss_config.source_image_reference.sku
    version   = var.vmss_config.source_image_reference.version
  }

  os_disk {
    caching              = var.vmss_config.os_disk_caching
    storage_account_type = var.vmss_config.os_disk_storage_account_type
    disk_size_gb         = var.vmss_config.os_disk_size_gb

  }

  network_interface {
    name    = "web-vmss-${module.naming.network_interface.name}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = module.vnet.subnets["web_tier"].resource_id

      load_balancer_backend_address_pool_ids = [
        module.loadbalancer["web"].azurerm_lb_backend_address_pool_id
      ]
    }
  }

  tags = local.common_tags

  depends_on = [module.vnet, module.loadbalancer]
}

resource "azurerm_monitor_autoscale_setting" "web_tier" {
  name                = "${local.product}-${local.environment}-web-autoscale"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.web_tier.id

  profile {
    name = var.autoscale_config.profile_name

    capacity {
      default = var.autoscale_config.capacity.default
      minimum = var.autoscale_config.capacity.minimum
      maximum = var.autoscale_config.capacity.maximum
    }

    dynamic "rule" {
      for_each = var.autoscale_config.rules
      content {
        metric_trigger {
          metric_name        = rule.value.metric_name
          metric_resource_id = azurerm_windows_virtual_machine_scale_set.web_tier.id
          time_grain         = rule.value.time_grain
          statistic          = rule.value.statistic
          time_window        = rule.value.time_window
          time_aggregation   = rule.value.time_aggregation
          operator           = rule.value.operator
          threshold          = rule.value.threshold
        }

        scale_action {
          direction = rule.value.scale_action.direction
          type      = rule.value.scale_action.type
          value     = rule.value.scale_action.value
          cooldown  = rule.value.scale_action.cooldown
        }
      }
    }
  }

  tags = local.common_tags
}

# #######################
# # Database Tier VM
# #######################

resource "azurerm_network_interface" "db_vm" {
  name                = var.database_nic_config.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = var.database_nic_config.ip_configuration.name
    subnet_id                     = module.vnet.subnets["database_tier"].resource_id
    private_ip_address_allocation = var.database_nic_config.ip_configuration.private_ip_address_allocation
  }

  tags = var.database_nic_config.tags
}

resource "azurerm_windows_virtual_machine" "db_vm" {
  name                  = var.database_vm_config.vm_name
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.db_vm.id]
  size                  = var.database_vm_config.vm_size

  computer_name  = var.database_vm_config.computer_name
  admin_username = var.admin_username
  admin_password = data.azurerm_key_vault_secret.secrets["db-admin-password"].value

  os_disk {
    name                 = var.database_vm_config.os_disk_name
    caching              = var.database_vm_config.os_disk_caching
    storage_account_type = var.database_vm_config.os_disk_storage_account_type
    disk_size_gb         = var.database_vm_config.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.database_vm_config.source_image_reference.publisher
    offer     = var.database_vm_config.source_image_reference.offer
    sku       = var.database_vm_config.source_image_reference.sku
    version   = var.database_vm_config.source_image_reference.version
  }

  tags = var.database_vm_config.tags

  depends_on = [module.vnet]
}


#######################
# Application Gateway
#######################

resource "azurerm_public_ip" "appgw" {
  name                = "${local.product}-${local.environment}-appgw-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = var.application_gateway_config.public_ip.allocation_method
  sku                 = var.application_gateway_config.public_ip.sku

  tags = local.common_tags
}


resource "azurerm_application_gateway" "this" {
  name                = var.application_gateway_config.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku {
    name     = var.application_gateway_config.sku_name
    tier     = var.application_gateway_config.sku_tier
    capacity = var.application_gateway_config.sku_capacity
  }

  gateway_ip_configuration {
    name      = var.application_gateway_config.gateway_ip_config_name
    subnet_id = module.vnet.subnets["appgw_tier"].resource_id
  }

  frontend_port {
    name = var.application_gateway_config.frontend_port_name
    port = var.application_gateway_config.listener_port
  }

  frontend_ip_configuration {
    name                 = var.application_gateway_config.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = var.application_gateway_config.backend_pool_name
  }

  backend_http_settings {
    name                  = var.application_gateway_config.backend_http_settings_name
    cookie_based_affinity = var.application_gateway_config.cookie_based_affinity
    port                  = var.application_gateway_config.backend_port
    protocol              = var.application_gateway_config.backend_protocol
    request_timeout       = var.application_gateway_config.request_timeout
  }

  http_listener {
    name                           = var.application_gateway_config.listener_name
    frontend_ip_configuration_name = var.application_gateway_config.frontend_ip_config_name
    frontend_port_name             = var.application_gateway_config.frontend_port_name
    protocol                       = var.application_gateway_config.listener_protocol
  }

  request_routing_rule {
    name                       = var.application_gateway_config.routing_rule_name
    rule_type                  = var.application_gateway_config.routing_rule_type
    http_listener_name         = var.application_gateway_config.listener_name
    backend_address_pool_name  = var.application_gateway_config.backend_pool_name
    backend_http_settings_name = var.application_gateway_config.backend_http_settings_name
    priority                   = var.application_gateway_config.routing_rule_priority
  }

  tags = var.application_gateway_config.tags

  depends_on = [module.vnet]
}

#######################
# Azure SQL Database
#######################

resource "random_password" "sql_admin" {
  length  = 24
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault.this
  ]
}

# Azure SQL Server
resource "azurerm_mssql_server" "this" {
  name                = var.sql_server_config.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  version                       = var.sql_server_config.version
  administrator_login           = var.sql_server_config.administrator_login
  administrator_login_password  = random_password.sql_admin.result
  minimum_tls_version           = var.sql_server_config.minimum_tls_version
  public_network_access_enabled = var.sql_server_config.public_network_access_enabled

  tags = var.sql_server_config.tags
}

# Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name      = "AllowAzureServices"
  server_id = azurerm_mssql_server.this.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "this" {
  name           = var.sql_database_config.name
  server_id      = azurerm_mssql_server.this.id
  collation      = var.sql_database_config.collation
  sku_name       = var.sql_database_config.sku_name
  max_size_gb    = var.sql_database_config.max_size_gb
  zone_redundant = var.sql_database_config.zone_redundant

  tags = var.sql_database_config.tags
}

#######################
# Azure Backup
#######################

resource "azurerm_recovery_services_vault" "this" {
  name                = var.recovery_services_vault_config.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku                 = var.recovery_services_vault_config.sku
  soft_delete_enabled = var.recovery_services_vault_config.soft_delete_enabled
  storage_mode_type   = var.recovery_services_vault_config.storage_mode_type

  tags = var.recovery_services_vault_config.tags
}

resource "azurerm_backup_policy_vm" "this" {
  name                = var.vm_backup_policy_config.name
  resource_group_name = azurerm_resource_group.this.name

  recovery_vault_name = azurerm_recovery_services_vault.this.name
  timezone            = var.vm_backup_policy_config.timezone

  backup {
    frequency = var.vm_backup_policy_config.backup.frequency
    time      = var.vm_backup_policy_config.backup.time
  }

  retention_daily {
    count = var.vm_backup_policy_config.retention_daily.count
  }

  retention_weekly {
    count    = var.vm_backup_policy_config.retention_weekly.count
    weekdays = var.vm_backup_policy_config.retention_weekly.weekdays
  }

  retention_monthly {
    count    = var.vm_backup_policy_config.retention_monthly.count
    weekdays = var.vm_backup_policy_config.retention_monthly.weekdays
    weeks    = var.vm_backup_policy_config.retention_monthly.weeks
  }
}

resource "azurerm_backup_protected_vm" "db_vm" {
  resource_group_name = azurerm_resource_group.this.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = azurerm_windows_virtual_machine.db_vm.id
  backup_policy_id    = azurerm_backup_policy_vm.this.id

  depends_on = [
    azurerm_windows_virtual_machine.db_vm,
    azurerm_backup_policy_vm.this
  ]
}

resource "azurerm_mssql_database_extended_auditing_policy" "this" {
  database_id            = azurerm_mssql_database.this.id
  storage_endpoint       = azurerm_recovery_services_vault.this.id
  retention_in_days      = var.sql_backup_policy_config.retention_daily.count
  log_monitoring_enabled = true
}

