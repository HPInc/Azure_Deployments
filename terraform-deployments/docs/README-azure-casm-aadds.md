# AWM (AADDS) Deployment

**Objective**: The objective of this documentation is to deploy a Azure Active Directory Domain Services on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS).

## Table of Contents
1. [AADDS Architecture](#1-aadds-architecture)
2. [Requirements](#2-requirements)
3. [Service Principal Authentication](#3-service-principal-authentication)
4. [Deploying the AADDS via Terraform](#4-aadds-deployment-steps)
5. [Configuring an existing AADDS](#5-configuring-an-existing-aadds)
6. [Deleting the deployment](#6-deleting-the-deployment)
7. [Common Deployment Issues](#7-common-deployment-issues)
8. [Videos](#8-videos)
9. [Troubleshooting](#9-troubleshooting)

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:
- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)


### 1. AADDS Architecture

The AADDS deployment creates a Virtual Network with 1 subnet in the same region as an AADDS (Azure Active Directory Domain Services) which is attached to this subnet. The Virtual Network DNS Servers are configured to point to the AADDS DNS servers.

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

As only one AADDS can be deployed per tenant, this deployment functions as a prerequisite to the other AWM deployments in this repository that use an AADDS as the domain. This limitation also means that the AADDS must be in the same region as the workstations the user plans to deploy as multi-region AADDS is not yet supported.

The terraform assumes a fresh deployment with no existing AADDS in the current tenant. For a smooth deployment and configuration process, it is highly recommended that users start with a fresh AADDS deployment following the steps outlined in this document, but for those who are unable Section 4 will be devoted to giving instructions in configuring an existing AADDS for use with other AWM deployments in this repository.

### 2. Requirements
- Access to a subscription on Azure.
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- An Azure account which has both the Application Administrator and Groups Administrator roles in the tenant, and the Domain Services Contributor role in the subscription
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)


### 3. Service principal Authentication
In order for Terraform to deploy & manage resources on a user's behalf, they must authenticate through a service principal.

Run the deploy script via `. deploy.sh` in the Azure Cloud Shell, this will provide and set the required users Subscription and Tenant ID environment variables

##### Option 1 (faster automated authentication):

The bash deploy script will automate the creation of a service principal and assign all of the required roles for deployment.

1. Upon completion of the deploy script, the Azure Cloud Shell will output the required Application ID and Client Secret which must be saved in the terraform.tfvars file
 ```
  {
  "appId": "xxxxxxxxxx",
  "displayName": "aadds_deployment",
  "password": "xxxxxxxxxx",
  "tenant": "xxxxxxxxxx"
  }
 ```
2. Open the terraform.tfvars file via `code terraform.tfvars` seen in section 4, step 3
3. Copy and paste the appId value into the application_id input field and the password value into the aad_client_secret input field
```
application_id                = "appId value here"
aad_client_secret             = "password value here"
tenant_id                     = "tenant value here"
```

4. The remaining information to be filled out includes providing the PCoIP Registration Code and all other desired workstation configurations. Save the file and skip to the remaining steps of deployment in section 4<br/>
**Note**: What if the Service Principal creation output values are lost or the Azure Cloud Shell times out?
In the instance that the Azure Cloud Shell times out or the output values are lost, the deploy script can be re-run and the previously created app and service principal will be patched and reset with a new client secret that users should update with. 
Otherwise, manual creation of the Service Principal and role assignments could be followed as seen by the steps in Option 2

##### Option 2 (slower manual authentication):

Running the deploy script will set the necessary environment variables for the User. Users are still able to manually authenticate via the Azure Portal using the following steps:

1. Login to the [Azure portal](http://portal.azure.com/)
2. Click **Azure Active Directory** in the left sidebar and click **App registrations** inside the opened blade.
3. Create a new application for the deployment by clicking **New registration**. If an application exists under **Owned applications**, this information can be reused. 
    - More detailed information on how to create a Service Principal can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
4. Copy the following information from the application overview: 
    - Client ID
    - Tenant ID
5. Under the same app, click **Certificates & secrets**.
6. Create a new Client Secret or use an existing secret. This value will only be shown once, make sure to save it.
7. Go to Subscriptions by searching **subscription** into the search bar and click on the subscription of choice.
8. Copy the **Subscription ID** and click on **Access control (IAM)** on the blade. 
9. Click **+ Add**, click **Add role assignments** and follow these steps to add roles:
    1. Under **Role**, click the dropdown and select the role **Reader**.
    2. Leave **Assign access to** as **User, group, or service principal**
    3. Under **Select** search for the application name from step 4 and click **Save**.
    4. Repeat steps i - iii for the role **Virtual Machine Contributor** and **Contributor**.

### 4. AADDS Deployment Steps

This deployment requires an account with the Application Administrator and Groups Administrator roles in the tenant, and the Domain Services Contributor role in the subscription. To check a users' tenant roles, search "Azure Active Directory" and navigate to the users pane. Find the user account that is being used for this deployment and navigate to "Assigned Roles", and ensure Application Administrator and Groups Administrator are both assigned. To check subscription roles, search "Subscriptions" and a list of all subscriptions in the directory will show up. Ensure that for the subscription this deployment is taking place in, the users' account is assigned at least a "Domain Services Contributor" role. The "Owner" role has also been verified to work.

If the user is missing any of these roles, contact the administrator of the Azure tenant.

 The steps to deploy a workstation will go as follows:
 1. Fill out AADDS terraform.tfvars file, and deploy the AADDS
 2. Wait for it to finish provisioning and syncing
 3. Enter AADDS information and other variables in the workstation deployment terraform.tfvars file, and deploy the workstations
 4. Configure AWM through the browser, test connections.


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
        - Subscription ID: ID of the subscription the AADDS will be deployed in. Found by searching "Subscriptions", going to the subscriptions page and copying the "Subscription ID"
        - aadds_rg_name: Name of the resource group that the AADDS will be deployed in. Limit 50 characters.
        - aadds_vnet_name: Name of the VNet that the AADDS will be deployed in. Limit 50 characters.
        - aadds_domain_name: Domain name of the AADDS. Must be either a domain that the user owns, or a *.onmicrosoft.com domain (e.g. teradici.onmicrosoft.com). *.onmicrosoft.com domains must be globally unique.
        - aadds_location: Location of the AADDS. As the AADDS is region-locked, this location must match the location of the workstations that the user plans to deploy. 
        - pfx_cert_password: Password of the PFX certificate that will be generated to configure the AADDS for LDAPS communication. Must be between 4-12 characters.
        - application_id : Service principal application id from section 3.
        - aad_client_secret: Service principal client secret from section 3.
```
4. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
5. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
    - **Note:** Users can also do ```terraform apply``` but often ACS will time out or there are scrolling limitations which prevents users from viewing all of the script output. ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose problems.
6. Answer ```yes``` to start provisioning the AADDS. 

A typical deployment should take around 30-40 minutes. When finished, the AADDS will need a further 30-40 minutes to provision, which can be monitored by going to the resource group and selecting the AADDS resource which is named after the configured domain, where the message shown below should be displayed:

![aadds_provision_message](/terraform-deployments/docs/png/aadds-provision.png)

After this is finished, the AADDS may still need a few more hours to sync the Azure AD users depending on the size of the directory.

IMPORTANT NOTE: For all cloud users in the Azure Active directory, each accounts' password must be either reset or changed following the deployment in order to sync with the AADDS due to the way AADDS handles password hashes. Failure to do so will mean that the account will be unavailable for use through the AADDS. More information on how the password sync works and why the reset is required here: https://docs.microsoft.com/en-us/azure/active-directory-domain-services/synchronization
    
### 5. Configuring an existing AADDS
This section goes over how to set up an existing AADDS deployment. If the AADDS was deployed with terraform as per the instructions in section 3, the AADDS should be ready and this section can be skipped. The rules and configurations below are required in being able to deploy AWM workstation deployments successfully. This list is not exhaustive, but covers the key configurations required in order for the AADDS to work with future deployments.
1. Go to the the resource group the AADDS belongs in and make note of the following variables: the resource group name, the name of the VNET the AADDS resides in, the location of the AADDS, and the domain name. These will be entered into AWM workstation deployments.
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

### 6. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform.
Terraform destroy will not work completely with this deployment as additional cleanup needs to happen on the Azure side for the destroy to finish. As terraform does not have formal support for the AADDS, terraform is unable to detect this. After running terraform destroy, the user will see a message some time later stating that some resources cannot be destroyed. Navigate to the AADDS resource and a message will appear on the top stating that the AADDS is being deleted. After this process is done, you can then destroy the resource group through Azure. Make sure to clean up the terraform state by typing ```rm *.tfstate*``` in ths directory before proceeding to re-deploy the AADDS.

### 7. Common Deployment Issues
Here are some common issues that might pop up during or after the deployment.

1. Forgetting to reset the password of your AAD service account during deployment - the deployment actually usually finishes and succeeds after a long time but nothing will be working correctly, but the bigger issue here is that since the deployment tries to log in with the credentials and fails, the user will be locked out of their account for a few hours or up to a day depending on the Azure AD settings from the failed login attempts. There is no way to fix this other than to create a new account or wait for the account to unlock.

2. Conflicting VNET CIDRs - The user might find that they have conflicting virtual network address spaces with other AWM deployments, which leads to a failed deployment. How it is currently set up is that each workstation deployment has vnet peering set up to connect to the AADDS, which means that each of the deployments requires a unique vnet address space. By default, the terraform deployment will try to find a non-conflicting address space but if the user decides to set it themselves they'll need to make sure theres no conflicts. Another issue can be that you run out but that will be much less common, since assuming a 16 bit vnet prefix you'll have 255 free address spaces to work with. 

3. The PFX certificate which is set up for LDAPS communication can expire, causing issues in connecting to the AADDS. The PFX certificate is currently set to expire after a year (it can be configured to be longer), in order to refresh it, see the Secure LDAP section to generate a new certificate.

4. If it complains that it could not find the service principal with appId `2565bd9d-da50-47d4-8b85-4c97f669dc36`, follow this steps with powershell.<br/>
   ##### 1) If needed, install the Azure AD PowerShell module and import it as follows:
   ```
   Install-Module AzureAD
   Import-Module AzureAD
    ```
   ##### 2) Register the Azure Active Directory Application Service Principal
   ```
   New-AzureAdServicePrincipal -AppId "2565bd9d-da50-47d4-8b85-4c97f669dc36"
   ```

### 8. Videos
A video of the deployment process for this terraform can be found on [Teradici's Youtube channel](https://www.youtube.com/watch?v=UvL8LwhGnb8)

### 9. Troubleshooting
- If the console looks frozen, try pressing Enter to unfreeze it.
- If the user encounters permission issues during deployment, ensure that the users' account is correctly assigned all the necessary roles.
