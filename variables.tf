variable "server_url" {
  type        = string
  description = "The url for the OpenShift api"
}

variable "login_user" {
  type        = string
  description = "Username for login"
  default     = ""
}

variable "login_password" {
  type        = string
  description = "Password for login"
  sensitive   = true
  default     = ""
}

variable "login_token" {
  type        = string
  description = "Token used for authentication"
  sensitive   = true
  default     = ""
}

variable "skip" {
  type        = bool
  description = "Flag indicating that the cluster login has already been performed"
  default     = false
}

variable "cluster_version" {
  type        = string
  description = "[Deprecated] The version of the cluster (passed through to the output)"
  default     = ""
}

variable "ingress_subdomain" {
  type        = string
  description = "[Deprecated] The ingress subdomain of the cluster (passed through to the output)"
  default     = ""
}

variable "tls_secret_name" {
  type        = string
  description = "[Deprecated] The name of the secret containing the tls certificates for the ingress subdomain (passed through to the output)"
  default     = ""
}

variable "ca_cert" {
  type        = string
  description = "The base64 encoded ca certificate"
  default     = ""
}

variable "ca_cert_file" {
  type        = string
  description = "The path to the file that contains the ca certificate"
  default     = ""
}

variable "user_cert" {
  type        = string
  description = "The base64 encoded user certificate"
  default     = ""
}

variable "user_cert_file" {
  type        = string
  description = "The path to the file that contains the user certificate"
  default     = ""
}

variable "user_key" {
  type        = string
  description = "The base64 encoded user key certificate"
  default     = ""
  sensitive   = true
}

variable "user_key_file" {
  type        = string
  description = "The path to the file that contains the user key certificate"
  default     = ""
}
