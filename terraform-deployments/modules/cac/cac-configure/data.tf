

# TODO should change this for something more secure
data "template_file" "cac_startup_template" {
  # Generate a templated start up script for each cac VM
  count = length(var.cac_ips)

  template = "${path.module}/files/cac-startup.sh"
  vars = {
    cac_installer_url           = var.cac_installer_url
    domain_controller_ip        = var.domain_controller_ip
    ad_service_account_username = var.ad_service_account_username
    ad_service_account_password = var.ad_service_account_password
    domain_name                 = var.domain_name
    cam_url                     = var.cam_url
    cac_token                   = var.cac_configuration[count.index].cac_token
    domain_group                = var.domain_group
    pcoip_registration_code     = var.pcoip_registration_code
    ssl_key                     = var.ssl_key
    ssl_cert                    = var.ssl_cert
    application_id              = var.application_id
    aad_client_secret           = var.aad_client_secret
    tenant_id                   = var.tenant_id
    pcoip_secret_key            = var.pcoip_secret_id
    ad_pass_secret_key          = var.ad_pass_secret_id
    cac_token_secret_key        = var.cac_token_secret_id
    _artifactsLocation          = var._artifactsLocation
  }
}