
variable "cluster_password" {
  type        = string
  description = "The api key for IBM Cloud access"
  default = ""
}

variable "cluster_token" {
  type        = string
  description = "The api key for IBM Cloud access"
  default = ""
}

variable "server_url" {
  type        = string
  description = "The url of the server."
}

variable "ingress_subdomain" {
  type = string
  default = ""
}

variable "cluster_username" {
  type = string
  default = "apikey"
}

variable "cluster_ca_cert" {
  type = string
  default = ""
}
