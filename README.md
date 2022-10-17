# OCP Login

Terraform module to log into a cluster and write the credentials into the kube config file. The file path is output by the module.

The module provides a number of ways to login to a cluster

-   User Token, the following variables need to be provided:
    -   server URL
    -   cluster_login_token
    -   (optionally) cluster_ca_cert or cluster_ca_cert_file
-   Username and Password, the following variables need to be provided:
    -   server URL
    -   cluster_login_user
    -   cluster_login_password
    -   (optionally) cluster_ca_cert or cluster_ca_cert_file
-   Client certificate, the following variables need to be provided:
    -   server URL
    -   cluster_login_user
    -   cluster_ca_cert or cluster_ca_cert_file
    -   cluster_user_cert or cluster_user_cert_file
    -   cluster_user_key or cluster_user_key_file

The certificates can either be passed as a base64 encoded string or a file path.  The variable name option ending in _file is used to pass a file path and the file must be available at the specified path within the environment where terraform is run

## Software dependencies

The module depends on the following software components:

### Command-line tools

-   terraform - v0.15

### Terraform providers

None

## Module dependencies

None

## Example usage

```hcl-terraform
module "dev_tools_argocd" {
  source = "github.com/ibm-garage-cloud/terraform-tools-argocd.git?ref=v1.0.0"

  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type        = module.dev_cluster.type
  app_namespace       = module.dev_cluster_namespaces.tools_namespace_name
  ingress_subdomain   = module.dev_cluster.ingress_hostname
  olm_namespace       = module.dev_software_olm.olm_namespace
  operator_namespace  = module.dev_software_olm.target_namespace
  name                = "argocd"
}
```

