output "id" {
  value       = data.external.cluster_info.result.cluster_id
  description = "ID of the cluster."
}

output "ocp_id" {
  value       = data.external.cluster_info.result.ocp_id
  description = "OpenShift ID of the cluster."
}

output "name" {
  value       = "cluster"
  description = "Name of the cluster"
  depends_on  = [data.external.oc_login]
}

output "region" {
  value       = ""
  description = "Region of the cluster"
  depends_on  = [data.external.oc_login]
}

output "resource_group_name" {
  value       = ""
  description = "Resource group of the cluster"
  depends_on  = [data.external.oc_login]
}

output "server_url" {
  value       = data.external.oc_login.result.serverUrl
  description = "The url of the control server."
}

output "username" {
  value       = data.external.oc_login.result.username
  description = "The username of the control server."
}

output "password" {
  value       = data.external.oc_login.result.password
  description = "The password of the control server."
  sensitive = true
}

output "token" {
  value       = data.external.oc_login.result.token
  description = "The token of the control server."
  sensitive = true
}

output "config_file_path" {
  value       = data.external.oc_login.result.kube_config
  description = "Path to the config file for the cluster."
}

output "platform" {
  value = {
    kubeconfig = data.external.oc_login.result.kube_config
    type       = data.external.cluster_info.result.platform_type
    type_code  = data.external.cluster_info.result.platform_code
    version    = data.external.cluster_info.result.cluster_version
    ingress    = data.external.cluster_info.result.ingress_subdomain
    tls_secret = data.external.cluster_info.result.tls_secret
  }
  description = "Configuration values for the cluster platform"
  depends_on  = [data.external.oc_login]
}

output "ca_cert" {
  value       = local.ca_cert
  description = "Base64 encoded CA certificate for cluster endpoints"
  depends_on = [data.external.oc_login]
}
