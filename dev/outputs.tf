#######################
# Load Balancer Outputs
#######################
output "load_balancer_public_ip" {
  description = "Public IP address of the load balancer"
  value       = { for k, lb in module.loadbalancer : k => lb.azurerm_public_ip_address }
}

output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = { for k, lb in module.loadbalancer : k => lb.azurerm_lb_id }
}

#######################
# Web Tier VMSS Outputs
#######################
output "web_vmss_id" {
  description = "ID of the web tier VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.web_tier.id
}

output "web_vmss_name" {
  description = "Name of the web tier VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.web_tier.name
}

output "web_vmss_unique_id" {
  description = "Unique ID of the web tier VMSS"
  value       = azurerm_windows_virtual_machine_scale_set.web_tier.unique_id
}

output "web_autoscale_setting_id" {
  description = "ID of the web tier autoscale setting"
  value       = azurerm_monitor_autoscale_setting.web_tier.id
}

output "web_availability_set_id" {
  description = "ID of the web tier availability set"
  value       = azurerm_availability_set.web_tier.id
}

#######################
# Network Outputs
#######################
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.resource_id
}

output "web_subnet_id" {
  description = "ID of the web tier subnet"
  value       = module.vnet.subnets["web_tier"].resource_id
}

output "database_subnet_id" {
  description = "ID of the database tier subnet"
  value       = module.vnet.subnets["database_tier"].resource_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT gateway"
  value       = azurerm_public_ip.nat_gateway.ip_address
}

#######################
# Key Vault Outputs
#######################
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "admin_username" {
  description = "Admin username for VMs (retrieve password from Key Vault)"
  value       = var.admin_username
}

#######################
# Application Gateway Outputs
#######################
output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_backend_pool_id" {
  description = "ID of the Application Gateway backend pool"
  value       = tolist(azurerm_application_gateway.this.backend_address_pool)[0].id
}

#######################
# SQL Database Outputs
#######################
output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.this.id
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name of the SQL Server"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "ID of the SQL Database"
  value       = azurerm_mssql_database.this.id
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.this.name
}

output "sql_admin_username" {
  description = "SQL Server admin username (retrieve password from Key Vault)"
  value       = var.sql_server_config.administrator_login
}
