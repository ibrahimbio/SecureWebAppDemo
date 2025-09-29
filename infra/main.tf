# infra/main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Tenant info
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.rg_name
  location = var.location
}

# Service Plan (Linux, S1) - Updated syntax
resource "azurerm_service_plan" "main" {
  name                = "SecurePlan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "S1"

  # Explicit dependency
  depends_on = [azurerm_resource_group.main]
}

# Web App - Updated for .NET 8.0 on Linux with explicit dependency
resource "azurerm_linux_web_app" "main" {
  name                = var.webapp_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
    always_on = true
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"   = "Production"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  https_only = true

  # Explicit dependency to ensure proper creation/deletion order
  depends_on = [azurerm_service_plan.main]
}

# Staging Slot - Updated syntax with explicit dependency
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
    always_on = true
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"   = "Staging"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  https_only = true

  # Explicit dependency to ensure proper deletion order
  depends_on = [azurerm_linux_web_app.main]
}

# Key Vault - Updated syntax with explicit dependency
resource "azurerm_key_vault" "main" {
  name                = var.kv_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # Updated properties
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  enable_rbac_authorization  = false

  # Access policy for the current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  # Access policy for the Web App's managed identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.main.identity[0].principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }

  # Explicit dependency
  depends_on = [azurerm_resource_group.main, azurerm_linux_web_app.main]
}

# Key Vault Secret with explicit dependency
resource "azurerm_key_vault_secret" "db_password" {
  name         = "DbPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id

  # Explicit dependency to ensure proper creation/deletion order
  depends_on = [azurerm_key_vault.main]
}