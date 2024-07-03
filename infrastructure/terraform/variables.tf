variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "region"
}

variable "auth_proxy_password" {
  type        = string
  description = "password for cloud sql"
  sensitive   = true
}
