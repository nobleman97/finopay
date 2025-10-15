# Finopay Development Infrastructure

This directory contains Terraform configuration for the development environment.

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.47.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for VMs (stored in Key Vault) | `string` | `"adminuser"` | no |
| <a name="input_application_gateway_config"></a> [application\_gateway\_config](#input\_application\_gateway\_config) | Configuration settings for Azure Application Gateway. | <pre>object({<br>    name              = string<br>    sku_name          = string<br>    sku_tier          = string<br>    sku_capacity      = number<br>    backend_port      = number<br>    backend_protocol  = string<br>    listener_port     = number<br>    listener_protocol = string<br>    request_timeout   = number<br>    public_ip = object({<br>      allocation_method = string<br>      sku               = string<br>    })<br>    gateway_ip_config_name     = string<br>    frontend_port_name         = string<br>    frontend_ip_config_name    = string<br>    backend_pool_name          = string<br>    backend_http_settings_name = string<br>    cookie_based_affinity      = string<br>    listener_name              = string<br>    routing_rule_name          = string<br>    routing_rule_type          = string<br>    routing_rule_priority      = number<br>    tags                       = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_autoscale_config"></a> [autoscale\_config](#input\_autoscale\_config) | Auto-scaling configuration for the VMSS. | <pre>object({<br>    profile_name = string<br>    capacity = object({<br>      default = number<br>      minimum = number<br>      maximum = number<br>    })<br>    rules = list(object({<br>      metric_name      = string<br>      time_grain       = string<br>      statistic        = string<br>      time_window      = string<br>      time_aggregation = string<br>      operator         = string<br>      threshold        = number<br>      scale_action = object({<br>        direction = string<br>        type      = string<br>        value     = string<br>        cooldown  = string<br>      })<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_availability_set"></a> [availability\_set](#input\_availability\_set) | Configuration settings for the availability set. | <pre>object({<br>    platform_update_domain_count = number<br>    platform_fault_domain_count  = number<br>    managed                      = bool<br>    tags                         = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_database_nic_config"></a> [database\_nic\_config](#input\_database\_nic\_config) | Configuration settings for the database tier network interface. | <pre>object({<br>    name = string<br>    ip_configuration = object({<br>      name                          = string<br>      private_ip_address_allocation = string<br>    })<br>    tags = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_database_vm_config"></a> [database\_vm\_config](#input\_database\_vm\_config) | Configuration settings for the database tier virtual machine. | <pre>object({<br>    vm_name                      = string<br>    vm_size                      = string<br>    computer_name                = string<br>    os_disk_name                 = string<br>    os_disk_caching              = string<br>    os_disk_storage_account_type = string<br>    os_disk_size_gb              = number<br>    source_image_reference = object({<br>      publisher = string<br>      offer     = string<br>      sku       = string<br>      version   = string<br>    })<br>    tags = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_key_vault_config"></a> [key\_vault\_config](#input\_key\_vault\_config) | Configuration settings for Azure Key Vault. | <pre>object({<br>    name                            = string<br>    sku_name                        = string<br>    enabled_for_disk_encryption     = bool<br>    enabled_for_deployment          = bool<br>    enabled_for_template_deployment = bool<br>    soft_delete_retention_days      = number<br>    purge_protection_enabled        = bool<br>    enable_rbac_authorization       = bool<br>    tags                            = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | Configuration settings for the load balancer. | <pre>map(object({<br>    type          = string<br>    sku           = string<br>    frontend_name = string<br>    remote_port = object({<br>      http = list(string)<br>    })<br>    lb_ports = object({<br>      http  = list(string)<br>      https = list(string)<br>    })<br>    lb_probes = object({<br>      http  = list(string)<br>      https = list(string)<br>    })<br>  }))</pre> | n/a | yes |
| <a name="input_nat_gateway_sku"></a> [nat\_gateway\_sku](#input\_nat\_gateway\_sku) | The SKU of the NAT Gateway. | `string` | `"Standard"` | no |
| <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method) | The allocation method of the Public IP. | `string` | `"Static"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | The SKU of the Public IP. | `string` | `"Standard"` | no |
| <a name="input_recovery_services_vault_config"></a> [recovery\_services\_vault\_config](#input\_recovery\_services\_vault\_config) | Configuration settings for Azure Recovery Services Vault. | <pre>object({<br>    name                         = string<br>    sku                          = string<br>    soft_delete_enabled          = bool<br>    storage_mode_type            = string<br>    cross_region_restore_enabled = bool<br>    tags                         = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_sql_backup_policy_config"></a> [sql\_backup\_policy\_config](#input\_sql\_backup\_policy\_config) | Configuration settings for SQL database backup policy. | <pre>object({<br>    name = string<br>    retention_daily = object({<br>      count = number<br>    })<br>    retention_weekly = object({<br>      count   = number<br>      weekday = string<br>    })<br>    retention_monthly = object({<br>      count   = number<br>      weekday = string<br>      week    = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_sql_database_config"></a> [sql\_database\_config](#input\_sql\_database\_config) | Configuration settings for Azure SQL Database. | <pre>object({<br>    name           = string<br>    collation      = string<br>    sku_name       = string<br>    max_size_gb    = number<br>    zone_redundant = bool<br>    tags           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_sql_server_config"></a> [sql\_server\_config](#input\_sql\_server\_config) | Configuration settings for Azure SQL Server. | <pre>object({<br>    name                          = string<br>    version                       = string<br>    administrator_login           = string<br>    minimum_tls_version           = string<br>    public_network_access_enabled = bool<br>    tags                          = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_vault_secrets"></a> [vault\_secrets](#input\_vault\_secrets) | List of Key Vault secret names to retrieve | `list(string)` | n/a | yes |
| <a name="input_vm_backup_policy_config"></a> [vm\_backup\_policy\_config](#input\_vm\_backup\_policy\_config) | Configuration settings for VM backup policy. | <pre>object({<br>    name     = string<br>    timezone = string<br>    backup = object({<br>      frequency = string<br>      time      = string<br>    })<br>    retention_daily = object({<br>      count = number<br>    })<br>    retention_weekly = object({<br>      count    = number<br>      weekdays = list(string)<br>    })<br>    retention_monthly = object({<br>      count    = number<br>      weekdays = list(string)<br>      weeks    = list(string)<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_vmss_config"></a> [vmss\_config](#input\_vmss\_config) | Configuration settings for the Virtual Machine Scale Set. | <pre>object({<br>    vm_size                      = string<br>    initial_instance_count       = number<br>    os_disk_caching              = string<br>    os_disk_storage_account_type = string<br>    os_disk_size_gb              = number<br>    source_image_reference = object({<br>      publisher = string<br>      offer     = string<br>      sku       = string<br>      version   = string<br>    })<br>    automatic_os_upgrade_policy = object({<br>      disable_automatic_rollback  = bool<br>      enable_automatic_os_upgrade = bool<br>    })<br>    automatic_instance_repair = object({<br>      enabled      = bool<br>      grace_period = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | The address space that is used by the virtual network. | `list(string)` | <pre>[<br>  "10.0.0.0/16"<br>]</pre> | no |

## Outputs

## Outputs

No outputs.
<!-- END_TF_DOCS -->
