# CASM (AADDS) Deployment

**Objective**: The objective of this documentation is to deploy a Azure Active Directory Domain Services on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS).

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:
- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
  - **[CASM (AADDS) Deployment](/terraform-deployments/docs/README-azure-casm-aadds.md)**
  - [CASM (Single-Connector) Deployment](/terraform-deployments/docs/README-azure-casm-single-connector.md)
  - [CASM (One-IP LB Deployment)](/terraform-deployments/docs/README-azure-casm-one-ip-lb.md)
  - [CASM (One-IP TF Deployment)](/terraform-deployments/docs/README-azure-casm-one-ip-tf.md)
  - [Quickstart (Single-Connector) Deployment](/terraform-deployments/deployments/quickstart-single-connector/quickstart-tutorial.md)
  - [CAS Manager (Single-Connector) Deployment](/terraform-deployments/docs/README-azure-cas-mgr-single-connector.md)
  - [Single-Connector Deployment](/terraform-deployments/docs/README-azure-single-connector.md)
  - [Local License Server (Single-Connector) Deployment](/terraform-deployments/docs/README-azure-lls-single-connector.md)
  - [Load Balancer (Multi-Connector) Deployment](/terraform-deployments/docs/README-azure-load-balancer.md)
  - [CAS Manager (Load Balancer) Deployment](/terraform-deployments/docs/README-azure-cas-mgr-load-balancer.md)
  - [CAS Manager (Load Balancer Single IP) Deployment](/terraform-deployments/docs/README-azure-cas-mgr-load-balancer-one-ip.md)
  - [CAS Manager (Load Balancer NAT Single IP) Deployment](/terraform-deployments/docs/README-azure-cas-mgr-load-balancer-one-ip-lb.md)
  - [Multi Region (Traffic Manager) Deployment](/terraform-deployments/docs/README-azure-multi-region-traffic-manager.md)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)

## Table of Contents
1. [Single-Connector Architecture](#1-aadds-architecture)
2. [Requirements](#2-requirements)
3. [Deploying the AADDS via Terraform](#3-deploying-the-aadds-via-terraform)
4. [Configuring an existing AADDS](#4-configuring-an-existing-aadds)
5. [Deleting the deployment](#5-deleting-the-deployment)
6. [Troubleshooting](#6-troubleshooting)
7. [Videos](#7-videos)

### 1. AADDS Architecture

The AADDS deployment creates a Virtual Network with 1 subnet in the same region as an AADDS (Azure Active Directory Domain Services) which is attached to this subnet. The Virtual Network DNS Servers are configured to point to the AADDS DNS servers.

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

As only one AADDS can be deployed per tenant, this deployment functions as a prerequisite to the other CASM deployments in this repository that use an AADDS as the domain. This limitation also means that the AADDS must be in the same region as the workstations the user plans to deploy as multi-region AADDS is not yet supported.

The terraform assumes a fresh deployment with no existing AADDS in the current tenant. For a smooth deployment and configuration process, it is highly recommended that users start with a fresh AADDS deployment following the steps outlined in this document, but for those who are unable Section 4 will be devoted to giving instructions in configuring an existing AADDS for use with other CASM deployments in this repository. 

### 2. Requirements
- Access to a subscription on Azure. 
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- An Azure account which has both the Global Administrator and Billing Administrator roles in the tenant, and the Contributor role in the subscription
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### 3. AADDS Deployment Steps

This deployment requires an account with the Global Administrator and Billing Administrator roles in the tenant, and the Contributor role in the subscription. To check a users' tenant roles, search "Azure Active Directory" and navigate to the users pane. Find the user account that is being used for this deployment and navigate to "Assigned Roles", and ensure Global Administrator and Billing Administrator are both assigned. To check subscription roles, search "Subscriptions" and a list of all subscriptions in the directory will show up. Ensure that for the subscription this deployment is taking place in, the users' account is assigned at least a "Contributor" role. The "Owner" role has also been verified to work. 

If the user is missing any of these roles, contact the administrator of the Azure tenant.

 The steps to deploy a workstation will go as follows:
 1. Fill out AADDS terraform.tfvars file, and deploy the AADDS
 2. Wait for it to finish provisioning and syncing
 3. Enter AADDS information and other variables in the workstation deployment terraform.tfvars file, and deploy the workstations
 4. Configure CASM through the browser, test connections.


terraform.tfvars is the file in which a user specifies variables for a deployment. The ```terraform.tfvars.sample``` sample file shows the required variables that a user must provide.

Before deploying, ```terraform.tfvars``` must be complete. 
1. Clone the repository into your Azure Cloud Shell (ACS) environment.
  - ```git clone https://github.com/teradici/Azure_Deployments```
2. Change directory into: ```/terraform-deployments/deployments/casm-aadds```.
3. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - To copy: ```cp terraform.tfvars.sample terraform.tfvars```
    - To configure: ```code terraform.tfvars```
    
    ```terraform.tfvars``` variables:
```
    AADDS configuration:
        - ```Subscrpition ID```: ID of the subscription the AADDS will be deployed in. Found by searching "Subscriptions", going to the subscriptions page and copying the "Subscription ID"
        - ```aadds_rg_name```: Name of the resource group that the AADDS will be deployed in. Limit 50 characters.
        - ```aadds_vnet_name```: Name of the VNet that the AADDS will be deployed in. Limit 50 characters.
        - ```aadds_domain_name```: Domain name of the AADDS. Must be either a domain that the user owns, or a *.onmicrosoft.com domain (e.g. teradici.onmicrosoft.com). *.onmicrosoft.com domains must be globally unique.
        - ```aadds_location```: Location of the AADDS. As the AADDS is region-locked, this location must match the location of the workstations that the user plans to deploy. 
        - ```pfx_cert_password```: Password of the PFX certificate that will be generated to configure the AADDS for LDAPS communication. Must be between 4-12 characters.
```
4. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
5. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
    - **Note:** Users can also do ```terraform apply``` but often ACS will time out or there are scrolling limitations which prevents users from viewing all of the script output. ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose problems.
6. Answer ```yes``` to start provisioning the AADDS. 

A typical deployment should take around 30-40 minutes. When finished, the AADDS will need a further 30-40 minutes to provision, which can be monitored by going to the resource group and selecting the AADDS resource which is named after the configured domain, where the message shown below should be displayed:

![aadds_provision_message](/terraform-deployments/docs/png/aadds-provision.png)

After this is finished, the AADDS may still need a few more hours to sync the Azure AD users depending on the size of the directory.

IMPORTANT NOTE: For all cloud users in the Azure Active directory, each accounts' password must be either reset or changed following the deployment in order to sync with the AADDS due to the way AADDS handles password hashes. Failure to do so will mean that the account will be unavailable for use through the AADDS. More information on how the password sync works and why the reset is required here: https://docs.microsoft.com/en-us/azure/active-directory-domain-services/synchronization
    
### 4. Configuring an existing AADDS
This section goes over how to set up an existing AADDS deployment. If the AADDS was deployed with terraform as per the instructions in section 3, the AADDS should be ready and this section can be skipped. The rules and configurations below are required in being able to deploy CASM workstation deployments successfully. This list is not exhaustive, but covers the key configurations required in order for the AADDS to work with future deployments.
1. Go to the the resource group the AADDS belongs in and make note of the following variables: the resource group name, the name of the VNET the AADDS resides in, the location of the AADDS, and the domain name. These will be entered into CASM workstation deployments.
2. Navigate to the "Secure LDAP" pane in the AADDS resource, and check if a certificate has been configured for LDAPS as per the settings below:
![secure_ldap](/terraform-deployments/docs/png/secure-ldap.png)
If a certificate has not been configured, navigate to ```/terraform-deployments/deployments/casm-aadds``` and run either generate_pfx.ps1 (Windows) or generate_pfx.sh (Linux or Mac). The scripts take two arguments: argument 1 is the domain name, and argument 2 will be the password. An example of how to run the scripts (when inside the casm-aadds directory): "./generate_pfx.sh teradici.onmicrosoft.com Password!234"
3. Create a NSG attached to the subnet the AADDS is attached to (if one does not already exist). After it has been created or if one already exists, navigate to it and click on "Inbound Security Rules" and click "Add". Add the following rules (or equivalent):
 ![inbound_security_rules](/terraform-deployments/docs/png/inbound-security.png)
Any conflicts with existing rules will need to be handled on a case by case basis.
4. Ensure that custom DNS servers are set up. Navigate to the virtual network the AADDS resides in and click on the "DNS Servers" pane. The resulting configuration should look similar to below: 
![aadds_dns](/terraform-deployments/docs/png/aadds_dns.png)
Make sure that the following 2 addresses point to the private addresses of the AADDS NICs found in the AADDS resource group, which are highlighted below:
![aadds-nic](/terraform-deployments/docs/png/aadds-nic.png)

5. If the Virtual Network does NOT have a cidr with 16 or more prefix bits, navigate to the peerings section of the virtual network settings and choose an address space for the following workstation deployment that does not conflict with an existing peering. If it does have 16 or more prefix bits, manually choosing an address space should not be 
necessary as the terraform deployment should be able to find one by default.

After these rules have been configured, the AADDS should be ready for future workstation deployments.
### 5. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform.
Terraform destroy will not work completely with this deployment as additional cleanup needs to happen on the Azure side for the destroy to finish. As terraform does not have formal support for the AADDS, terraform is unable to detect this. After running terraform destroy, the user will see a message some time later stating that some resources cannot be destroyed. Navigate to the AADDS resource and a message will appear on the top stating that the AADDS is being deleted. After this process is done, you can then destroy the resource group through Azure. Make sure to clean up the terraform state by typing ```rm *.tfstate*``` in ths directory before proceeding to re-deploy the AADDS.

### 6. Common issues during deployment
Here are some common issues that might pop up during or after the deployment. 

### 7. Videos
A video of the deployment process for this terraform can be found on [Teradici's Youtube channel](https://www.youtube.com/watch?v=UvL8LwhGnb8)

1. Forgetting to reset the password of your AAD service account during deployment - the deployment actually usually finishes and succeeds after a long time but nothing will be working correctly, but the bigger issue here is that since the deployment tries to log in with the credentials and fails, the user will be locked out of their account for a few hours or up to a day depending on the Azure AD settings from the failed login attempts. There is no way to fix this other than to create a new account or wait for the account to unlock.

2. Conflicting VNET CIDRs - The user might find that they have conflicting virtual network address spaces with other CASM deployments, which leads to a failed deployment. How it is currently set up is that each workstation deployment has vnet peering set up to connect to the AADDS, which means that each of the deployments requires a unique vnet address space. By default, the terraform deployment will try to find a non-conflicting address space but if the user decides to set it themselves they'll need to make sure theres no conflicts. Another issue can be that you run out but that will be much less common, since assuming a 16 bit vnet prefix you'll have 255 free address spaces to work with. 

3. The PFX certificate which is set up for LDAPS communication can expire, causing issues in connecting to the AADDS. The PFX certificate is currently set to expire after a year (it can be configured to be longer), in order to refresh it, see the Secure LDAP section to generate a new certificate.

### 7.. Troubleshooting
- If the console looks frozen, try pressing Enter to unfreeze it.
- If the user encounters permission issues during deployment, ensure that the users' account is correctly assigned all the necessary roles.