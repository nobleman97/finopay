variable "vnet_address_space" {
  description = "The address space that is used by the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "nat_gateway_sku" {
  description = "The SKU of the NAT Gateway."
  type        = string
  default     = "Standard"
}

variable "public_ip_sku" {
  description = "The SKU of the Public IP."
  type        = string
  default     = "Standard"
}

variable "public_ip_allocation_method" {
  description = "The allocation method of the Public IP."
  type        = string
  default     = "Static"
}

variable "load_balancers" {
  description = "Configuration settings for the load balancer."
  type = map(object({
    type          = string
    sku           = string
    frontend_name = string
    remote_port = object({
      http = list(string)
    })
    lb_ports = object({
      http  = list(string)
      https = list(string)
    })
    lb_probes = object({
      http  = list(string)
      https = list(string)
    })
  }))
}

variable "availability_set" {
  description = "Configuration settings for the availability set."
  type = object({
    platform_update_domain_count = number
    platform_fault_domain_count  = number
    managed                      = bool
    tags                         = map(string)
  })
}

variable "vmss_config" {
  description = "Configuration settings for the Virtual Machine Scale Set."
  type = object({
    vm_size                      = string
    initial_instance_count       = number
    os_disk_caching              = string
    os_disk_storage_account_type = string
    os_disk_size_gb              = number
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    automatic_os_upgrade_policy = object({
      disable_automatic_rollback  = bool
      enable_automatic_os_upgrade = bool
    })
    automatic_instance_repair = object({
      enabled      = bool
      grace_period = string
    })
  })
}

variable "autoscale_config" {
  description = "Auto-scaling configuration for the VMSS."
  type = object({
    profile_name = string
    capacity = object({
      default = number
      minimum = number
      maximum = number
    })
    rules = list(object({
      metric_name      = string
      time_grain       = string
      statistic        = string
      time_window      = string
      time_aggregation = string
      operator         = string
      threshold        = number
      scale_action = object({
        direction = string
        type      = string
        value     = string
        cooldown  = string
      })
    }))
  })
}

variable "database_vm_config" {
  description = "Configuration settings for the database tier virtual machine."
  type = object({
    vm_name                      = string
    vm_size                      = string
    computer_name                = string
    os_disk_name                 = string
    os_disk_caching              = string
    os_disk_storage_account_type = string
    os_disk_size_gb              = number
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    tags = map(string)
  })
}

variable "database_nic_config" {
  description = "Configuration settings for the database tier network interface."
  type = object({
    name = string
    ip_configuration = object({
      name                          = string
      private_ip_address_allocation = string
    })
    tags = map(string)
  })
}

variable "key_vault_config" {
  description = "Configuration settings for Azure Key Vault."
  type = object({
    name                            = string
    sku_name                        = string
    enabled_for_disk_encryption     = bool
    enabled_for_deployment          = bool
    enabled_for_template_deployment = bool
    soft_delete_retention_days      = number
    purge_protection_enabled        = bool
    enable_rbac_authorization       = bool
    tags                            = map(string)
  })
}

variable "admin_username" {
  description = "Admin username for VMs (stored in Key Vault)"
  type        = string
  default     = "adminuser"
}

variable "application_gateway_config" {
  description = "Configuration settings for Azure Application Gateway."
  type = object({
    name     = string
    sku_name = string
    sku_tier = string
    sku_capacity = number
    backend_port = number
    backend_protocol = string
    listener_port = number
    listener_protocol = string
    request_timeout = number
    tags = map(string)
  })
}

variable "sql_server_config" {
  description = "Configuration settings for Azure SQL Server."
  type = object({
    name                         = string
    version                      = string
    administrator_login          = string
    minimum_tls_version          = string
    public_network_access_enabled = bool
    tags                         = map(string)
  })
}

variable "sql_database_config" {
  description = "Configuration settings for Azure SQL Database."
  type = object({
    name                = string
    collation           = string
    sku_name            = string
    max_size_gb         = number
    zone_redundant      = bool
    tags                = map(string)
  })
}