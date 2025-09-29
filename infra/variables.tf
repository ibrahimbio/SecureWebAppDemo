# infra/variables.tf
variable "rg_name" {
  description = "Name of the resource group"
  type        = string
  default     = "SecureRG"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "italynorth"
}

variable "webapp_name" {
  description = "Name of the web app"
  type        = string
  default     = "securewebapp33800"
}

variable "kv_name" {
  description = "Name of the Key Vault (must be globally unique)"
  type        = string
  default     = "securekv3300"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "TempPassword123!"
}