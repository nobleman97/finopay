# Network Configuration
vnet_address_space = ["10.0.0.0/16"]

nat_gateway_sku             = "Standard"
public_ip_sku               = "Standard"
public_ip_allocation_method = "Static"

load_balancers = {
  web = {
    type          = "public"
    sku           = "Standard"
    frontend_name = "frontend-finopay"
    remote_port = {
      http = ["Tcp", "80"]
    }
    lb_ports = {
      http  = ["80", "Tcp", "80"]
      https = ["443", "Tcp", "443"]
    }
    lb_probes = {
      http  = ["Tcp", "80", ""]
      https = ["Tcp", "443", ""]
    }
  }
}

availability_set = {
  platform_update_domain_count = 5
  platform_fault_domain_count  = 2
  managed                      = true
  tags = {
    environment = "dev"
    tier        = "web"
  }
}

admin_username = "adminuser"

vmss_config = {
  vm_size                      = "Standard_D2s_v3"
  initial_instance_count       = 2
  os_disk_caching              = "ReadWrite"
  os_disk_storage_account_type = "Premium_ZRS"
  os_disk_size_gb              = 128

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  automatic_os_upgrade_policy = {
    disable_automatic_rollback  = false
    enable_automatic_os_upgrade = false
  }

  automatic_instance_repair = {
    enabled      = true
    grace_period = "PT30M" # 30 minutes
  }
}

autoscale_config = {
  profile_name = "default"

  capacity = {
    default = 2
    minimum = 2
    maximum = 10
  }

  rules = [
    {
      metric_name      = "Percentage CPU"
      time_grain       = "PT1M"
      statistic        = "Average"
      time_window      = "PT5M"
      time_aggregation = "Average"
      operator         = "GreaterThan"
      threshold        = 75

      scale_action = {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    },
    {
      metric_name      = "Percentage CPU"
      time_grain       = "PT1M"
      statistic        = "Average"
      time_window      = "PT5M"
      time_aggregation = "Average"
      operator         = "LessThan"
      threshold        = 25

      scale_action = {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  ]
}

database_nic_config = {
  name = "nic-db-vm-finopay-dev-001"
  ip_configuration = {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    environment = "dev"
    tier        = "database"
  }
}

database_vm_config = {
  vm_name                      = "vm-db-finopay-dev"
  vm_size                      = "Standard_D4s_v3"
  computer_name                = "db-vm"
  os_disk_name                 = "osdisk-db-vm-finopay-dev"
  os_disk_caching              = "ReadWrite"
  os_disk_storage_account_type = "Premium_ZRS"
  os_disk_size_gb              = 256

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "dev"
    tier        = "database"
  }
}

key_vault_config = {
  name                            = "kv-finopay-dev-001"
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 90
  purge_protection_enabled        = false
  enable_rbac_authorization       = false # I would implemeent RBAC normally

  tags = {
    environment = "dev"
    purpose     = "vm-credentials"
  }
}

application_gateway_config = {
  name              = "appgw-finopay-dev"
  sku_name          = "Standard_v2"
  sku_tier          = "Standard_v2"
  sku_capacity      = 2
  backend_port      = 80
  backend_protocol  = "Http"
  listener_port     = 80
  listener_protocol = "Http"
  request_timeout   = 20
  public_ip = {
    allocation_method = "Static"
    sku               = "Standard"
  }
  gateway_ip_config_name     = "appgw-ip-config"
  frontend_port_name         = "frontend-port"
  frontend_ip_config_name    = "frontend-ip-config"
  backend_pool_name          = "web-backend-pool"
  backend_http_settings_name = "backend-http-settings"
  cookie_based_affinity      = "Disabled"
  listener_name              = "http-listener"
  routing_rule_name          = "routing-rule"
  routing_rule_type          = "Basic"
  routing_rule_priority      = 100
  tags = {
    environment = "dev"
    tier        = "application-gateway"
  }
}

sql_server_config = {
  name                          = "sqlserver-finopay-dev"
  version                       = "12.0"
  administrator_login           = "sqladmin"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  tags = {
    environment = "dev"
    tier        = "database"
  }
}

sql_database_config = {
  name           = "sqldb-finopay-dev"
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "S0"
  max_size_gb    = 250
  zone_redundant = false
  tags = {
    environment = "dev"
    tier        = "database"
  }
}


vault_secrets = [
  "db-admin-password",
  "vmss-admin-password",
  "sql-admin-password"
]

recovery_services_vault_config = {
  name                         = "rsv-finopay-dev"
  sku                          = "Standard"
  soft_delete_enabled          = true
  storage_mode_type            = "GeoRedundant"
  cross_region_restore_enabled = false
  tags = {
    environment = "dev"
    purpose     = "backup"
  }
}

vm_backup_policy_config = {
  name     = "vm-backup-policy-daily"
  timezone = "UTC"
  backup = {
    frequency = "Daily"
    time      = "23:00"
  }
  retention_daily = {
    count = 30
  }
  retention_weekly = {
    count    = 12
    weekdays = ["Sunday"]
  }
  retention_monthly = {
    count    = 12
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}

sql_backup_policy_config = {
  name = "sql-backup-policy"
  retention_daily = {
    count = 7
  }
  retention_weekly = {
    count   = 4
    weekday = "Sunday"
  }
  retention_monthly = {
    count   = 12
    weekday = "Sunday"
    week    = "First"
  }
}

