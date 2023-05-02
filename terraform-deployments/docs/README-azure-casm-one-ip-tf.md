# AWM Multi-Region Multi Load Balancer Traffic Manager Deployment

**Objective**: The objective of this documentation is to deploy the Traffic Manager Single IP architecture on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS).

## Table of Contents
1. [AWM-Traffic-Manager-One-IP Architecture](#1-awm-traffic-manager-one-ip-architecture)
2. [Requirements](#2-requirements)
3. [Service Principal Authentication](#3-service-principal-authentication)
4. [Variable Assignment](#4-variable-assignment)
5. [Storing Secrets on Azure Keyvault](#5-optional-storing-secrets-on-azure-key-vault)
6. [Assigning a SSL Certificate](#6-optional-assigning-a-ssl-certificate)
7. [Deploying the Traffic-Manager-One-IP via Terraform](#7-deploying-the-Traffic-Manager-One-IP-via-terraform)
8. [Adding Workstations in Anyware Manager](#8-adding-workstations-in-anyware-manager)
9. [Starting a PCoIP Session](#9-starting-a-pcoip-session)
10. [Changing the deployment](#10-changing-the-deployment)
11. [Deleting the deployment](#11-deleting-the-deployment)
12. [Troubleshooting](#12-troubleshooting)

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:
- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)


### 1. AWM-Traffic-Manager-One-IP Architecture

The Traffic-Manager-One-IP deployment creates a Virtual Network with 3 subnets in the same region. The subnets created are:
- ```subnet-cac```: for the Connector
- ```subnet-cas```: for the AWM
- ```subnet-ws```: for the workstations

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

A Cloud Access Connector is created and registers itself with the Anyware Manager service with the given token and PCoIP registration code.

This deployment runs the Anyware Manager in a virtual machine which gives users full control of the Anyware deployment, which is also reached through the firewall. The Anyware deployment will not have to reach out to the internet for Anyware management features, but the user is responsible for costs, security, updates, high availability and maintenance of the virtual machine running Anyware Manager. All resources in this deployment are created without a public IP attached and all external traffic is routed through the Azure Firewall both ways through the firewall NAT, whose rules are preconfigured. This architecture is shown in the diagram below:

Multiple domain-joined workstations and Cloud Access Connectors can be optionally created, specified by the following respective parameters:
- ```workstations```: List of objects, where each object defines a workstation
- ```cac_configuration```: List of objects, where each object defined a connector

The ```workstation_os``` property in the ```workstations``` parameter can be used to define the respective workstation's operating system (use 'linux' or 'windows'). 

The Traffic Manager distributes traffic between Cloud Access Connectors within the same region. The client initiates a PCoIP session with the domain name of the Traffic Manager, and the Traffic Manager selects one of the connectors in it's region to establish the connection. In-session PCoIP traffic goes through configured frontend IPs on a NAT Gateway which have rules set up to route into the selected Cloud Access Connector, bypassing the Traffic Manager.

This deployment makes use of the AADDS as the active directory. Since only 1 AADDS can be deployed per tenant, refer to the [AWM-AADDS document](./README-azure-casm-aadds.md) to deploy/configure an AADDS before continuing with this deployment if an AADDS has not yet been configured.

As the deployment makes use of an internal keyvault and database for storage, key vault secret configuration is not available for this deployment.

Each workstation can be configured with a graphics agent by using the ```isGFXHost``` property of the ```workstations``` parameter.

These workstations are automatically domain-joined to the AADDS and have the PCoIP Agent installed.

Note: Please make sure that the following variables are synced from the previous AADDS Deployment that the```location``` property in the ```workstations``` parameter is in sync with the ```aadds_location``` property defined in the AADDS deployment, or with the existing AADDS location. 

### 2. Requirements
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- an Anyware Manager Deployment Service Account. Anyware Manager can be accessed [here](https://cas.teradici.com/)
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- An existing AADDS deployment (see the [AWM-AADDS documentation](./README-azure-casm-aadds.md)).
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### 3. Service Principal Authentication
In order for Terraform to deploy & manage resources on a user's behalf, they must authenticate through a service principal. 

Run the deploy script via `. deploy.sh` in the Azure Cloud Shell, this will provide and set the required users Subscription and Tenant ID environment variables

##### Option 1 (faster automated authentication):

The bash deploy script will automate the creation of a service principal and assign all of the required roles for deployment.

1. Upon completion of the deploy script, the Azure Cloud Shell will output the required Application ID and Client Secret which must be saved in the terraform.tfvars file
 ```
  {
  "appId": "xxxxxxxxxx",
  "displayName": "casm_tf_one_ip",
  "password": "xxxxxxxxxx",
  "tenant": "xxxxxxxxxx"
  }
 ```
2. Open the terraform.tfvars file via `code terraform.tfvars` seen in section 6, step 3
3. Copy and paste the appId value into the application_id input field and the password value into the aad_client_secret input field
```
application_id                = "appId value here"
aad_client_secret             = "password value here"
tenant_id                     = "tenant value here"
```
   The object_id can be obtained from the Azure portal under the created app registration 
4. The remaining information to be filled out includes providing the PCoIP Registration Code and all other desired workstation configurations. Save the file and skip to the remaining steps of deployment in section 7
**Note**: What if the Service Principal creation output values are lost or the Azure Cloud Shell times out?
In the instance that the Azure Cloud Shell times out or the output values are lost, the deploy script can be re-run and the previously created app and service principal will be patched and reset with a new client secret that users should update with. 
Otherwise, manual creation of the Service Principal and role assignments could be followed as seen by the steps in Option 2

##### Option 2 (slower manual authentication):

Running the deploy script will set the necessary environment variables for the User. Users are still able to manually authenticate via the Azure Portal using the following steps

1. Login to the [Azure portal](http://portal.azure.com/)
2. Click **Azure Active Directory** in the left sidebar and click **App registrations** inside the opened blade.
3. Create a new application for the deployment by clicking **New registration**. If an application exists under **Owned applications**, this information can be reused. 
    - More detailed information on how to create a Service Principal can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
4. Copy the following information from the application overview: 
    - Client ID
    - Tenant ID
    - Object ID
5. Under the same app, click **Certificates & secrets**.
6. Create a new Client Secret or use an existing secret. This value will only be shown once, make sure to save it.
7. Go to Subscriptions by searching **subscription** into the search bar and click on the subscription of choice.
8. Copy the **Subscription ID** and click on **Access control (IAM)** on the blade. 
9. Click **+ Add**, click **Add role assignments** and follow these steps to add roles:
    1. Under **Role**, click the dropdown and select the role **Reader**.
    2. Leave **Assign access to** as **User, group, or service principal**
    3. Under **Select** search for the application name from step 4 and click **Save**.
    4. Repeat steps i - iii for the role **Virtual Machine Contributor** and **Contributor**.

### 4. Variable Assignment
---IMPORTANT NOTE: All AADDS Deployments require login credentials from an account in the Azure Active Directory of the tenant the deployment is taking place in. These credentials are entered in the tfvars file as detailed below. In order for accounts in the Azure Active Directory to sync with the AADDS, the accounts' password must either be changed or reset AFTER the AADDS has finished deploying and provisioning. For reasons on why this is, refer to (https://docs.microsoft.com/en-us/azure/active-directory-domain-services/synchronization). Failure to do so will result in the deployment failing due to failed login attempts and the Active Directory user account being locked. Therefore, only enter the ad_admin_password below AFTER it has been changed following the AADDS deployment.---

4. Fill in the following variables. Below is a completed example with tips underneath that can aid in finding the values.
```
ad_admin_username             = "aadds_user"
ad_admin_password             = "AADDS_Password1!"
safe_mode_admin_password      = "Password!234"
cas_mgr_admin_password        = "Password!234"
mongodb_admin_password        = "Password!234"
pcoip_registration_code       = "ABCDEFGHIJKL@0123-4567-89AB-CDEF

aadds_vnet_name               = "AAD_DS_TeraVNet"
aadds_vnet_rg                 = "AAD_DS_Teradici"
aadds_domain_name             = "example.onmicrosoft.com"

application_id                = "4928a0xd-e1re-592l-9321-5f114953d88c"
aad_client_secret             = "J492L_1KR2plr1SQdgndGc~gE~pQ.eR3F."
tenant_id                     = "31f56g8-1k3a-q43e-1r3x-dc340b62cf18"
object_id                     = "4913cc14-2c26-4054-9d98-faea1e34213c"

traffic_manager_dns_name = "teradici-aadds-example"

```
- Tips for finding these variables:
    1. ```application_id```, ```tenant_id```, and ```object_id``` are from [section 3](#3-service-principal-authentication) step 4.
    2. ```aad_client_secret```: This is the same secret from [section 3](#3-service-principal-authentication). If this secret is no longer saved, follow section 3 from steps 1-3 & 5-6 to obtain a new client secret.
    3. ad_admin_username is the username of an account belonging to the Azure Active Directory in the current tenant.
    4. ad_admin_password is the password of an account belonging to the Azure Active Directory in the current tenant.
    5. ```aadds_vnet_name``` is the VNet Name of the previously configured AADDS deployment, the property must be in in sync with the ```aadds_vnet_name``` property defined in the AADDS deployment, or with the existing AADDS Virtual Network Name.
    6. ```aadds_vnet_rg``` is the Resource Group Name of the previously configured AADDS deployment, the property must be in sync with the ```aadds_vnet_rg``` property defined in the AADDS deployment, or with the existing AADDS resource group name.
    7. ```aadds_domain_name``` is the Domain Name of the previously configured AADDS deployment, property must be in sync with the ```aadds_domain_name``` property defined in the AADDS deployment, or with the existing AADDS domain name.
    8. ```traffic_manager_dns_name``` is the DNS name of the traffic manager which users will connect to. Must be globally unique.
    9. (Optional) ```aadds_vnet_cidr``` is the CIDR of the address space the VNET will be created with. This must not conflict with the CIDRs of any other AWM deployments. By default, the terraform deployment looks up the addresses of existing AWM deployments and selects a non-conflicting CIDR.

### 5. (Optional) Storing Secrets on Azure Key Vault

**Note**: This is optional. Users may skip this section and enter plaintext for the AD admin password, safe mode admin password, PCoIP registration key, and connector token in terraform.tfvars.

As a security method to help protect the AD safe mode admin password, AD admin password, PCoIP registration key,  LLS admin password, connector token, and LLS activation code users can store them as secrets in an Azure Key Vault. Secrets will be decrypted in the configuration scripts.

1. In the Azure portal, search for **Key Vault** and click **+ Add** to create a new key vault. 
    1. Select the same region as the deployment.
    2. Click next to go to the Access policy page.
    3. Click **+ Add Access Policy**.
        1. Under **Configure from template** select **Secret Management**.
        2. Under **Select principal** click on **None selected**.
        3. Find the application from [section 3](#3-service-principal-authentication) and click **Select**. The ID underneath should match the Client ID/Application ID saved from earlier.
        4. Click **Review + create** and then **Create**.
2. Click on the key vault that was created and click on **Secrets** inside the rightmost blade.
3. To create **AD safe mode admin password**, **AD admin password**, **LLS admin password**, **PCoIP registration key**, **connector token** and **LLS activation code** as secrets follow these steps for each value:
    1. Click **+ Generate/Import**.
    2. Enter the name of the secret.
    3. Input the secret value.
    4. Click **Create**.
    5. Click on the secret that was created, click on the version and copy the **Secret Identifier**. 
      - **Tip**: To reduce the chance of errors, verify the secret is correct by clicking on **Show Secret Value**.
4. Fill in the following variables. Below is a completed example with tips underneath that can aid in finding the values.
```
...

# Only fill these when using Azure Key Vault secrets.
# Examples and tips can be found in section 4 of the documentation.
# key_vault_id                  = "/subscriptions/12e06/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/mykeyvault"
# ad_pass_secret_name           = "adPasswordID"
```
- Tips for finding these variables:
    1. ```key_vault_id```: Go to the key vault containing the secrets on the Portal and click on **Properties** inside the opened blade. Copy the **Resource ID**.
    2. ```ad_pass_secret_name```: This is the name used for the ad pass secret. The name can be seen after```/secrets/``` from the variable ```ad_admin_password```. From the example above, this would be ```adPasswordID```.
    
### 6. (Optional) Assigning a SSL Certificate

**Note**: This is optional. Assigning a SSL certificate will prevent the PCoIP client from reporting an insecure connection when establishing a PCoIP session though users may still connect. Read more [here](https://www.teradici.com/web-help/anyware_manager/current/cloud_access_connector/certificate_cas_connector/). It is also an option to assign an SSL certificate **after** the completion of the script. More information can be found [here](https://www.teradici.com//web-help/anyware_manager/current/cloud_access_connector/cas_connector_update/#updating-ssl-certificates).

To upload a SSL certificate and SSL key onto ACS:
  1. Go into the **Resource group** that contains ACS storage. By default, the name should look like: **cloud-shell-storage-[region]**
  2. Click on the storage account being used for deployment.
  3. Next, click **File shares** and then click the file share that is mounted onto ACS.
  4. Upload the SSL certificate and SSL key. Must be in .pem format.
  5. The location of these files will be found in ```~/clouddrive/```
  6. Enter the paths to the SSL certificate and SSL key inside ```terraform.tfvars```.

### 7. Deploying the AWM-TF-One-IP via Terraform
terraform.tfvars is the file in which a user specifies variables for a deployment. The ```terraform.tfvars.sample``` sample file shows the required variables that a user must provide, along with other commonly used but optional variables. 

**Note**: Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

Before deploying, ```terraform.tfvars``` must be complete and an AADDS Deployment must be completed and fully provisioned. 
1. Clone the repository into your Azure Cloud Shell (ACS) environment.
  - ```git clone https://github.com/teradici/Azure_Deployments```
2. Change directory into: ```/terraform-deployments/deployments/casm-one-ip-tf```.
  - ```cd Azure_Deployments/terraform-deployments/deployments/casm-one-ip-tf```.
2. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - To copy: ```cp terraform.tfvars.sample terraform.tfvars```
    - To configure: ```code terraform.tfvars```
    - To include optional variables, uncomment the line by removing preceding ```#```.
    - Make sure the locations of the connectors and work stations are identical.
    
    ```terraform.tfvars``` variables:

    1. workstation configuration:
        - ```prefix```: prefix added to workstation machines. e.g.: 'tera0' will name a standard Linux VM **tera0**-scent-0
            -   Must be a max of 5 characters to avoid name cropping. Can be left blank.
        - ```location```: location of the workstation. **westus** machines will be placed in the West US region. 
            -   Possible values: [Regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/). 
            -   e.g. West US 2 will be inputted as **westus2**. Central US as **centralus**.
        - ```workstation_os```: Operating system of the workstation.
            -   Possible values: **windows** or **linux**
        - ```vm_size```: Size of the virtual machine. 
            -   Possible values: [VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes). 
        - ```disk_type```: Type of storage for the workstation. 
            -   Possible values: **Standard_LRS**, **StandardSSD_LRS** or **Premium_LRS**
        - ```count```: Number of workstations to deploy under the specific settings.
        - ```isGFXHost```: Determines if a Grahpics Agent will be installed. Graphics agents require [**NV-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) or [**NCasT4_v3-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series). The default size in .tfvars is **Standard_NV12s_v3**. Additional VM sizes can be seen in the [**Appendix**](#appendix)
            -   Possible values: **true** or **false**
      2. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
      3. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
          - **Note:** Users can also do ```terraform apply``` but often ACS will time out or there are scrolling limitations which prevents users from viewing all of the script output. ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose problems.
      4. Answer ```yes``` to start provisioning the load balancer infrastructure. 

A typical deployment should take around 40-50 minutes. When finished, the scripts will display VM information such as IP addresses. At the end of the deployment, the resources may still take a few minutes to start up completely. It takes a few minutes for a connector to sync with the Anyware Manager so **Health** statuses may show as **Unhealthy** temporarily. 

Example output:
```
Apply complete! Resources: 67 added, 0 changed, 0 destroyed.

Outputs:

cas-mgr-public-ip = "52.109.24.178"
centos-graphics-workstations = [
  {
    "name" = "gcent-0"
    "private_ip" = "10.0.4.5"
  },
]
centos-standard-workstations = [
  {
    "name" = "scent-0"
    "private_ip" = "10.0.4.6"
  },
]
resource_group = "casm_single_connector_c4fe3"
windows-standard-workstations = [
  {
    "name" = "swin-0"
    "private_ip" = "10.0.4.4"
  },
]
windows-graphics-workstations = [
  {
    "name" = "gwin-0"
    "private_ip" = "10.0.4.7"
  },
]
traffic-manager-domain-name = "teradici.trafficmanager.net"
```

    
### 8. Adding Workstations in Anyware Manager
To connect to workstations, they have to be added through Anyware Manager. 
1. In a browser, enter ```https://<cas-mgr-public-ip>```.
    - The default username for Anyware Manager is ```adminUser```.
2. Click Workstations on the left sidebar, click the blue **+** and select **Add existing remote workstation**. 
3. From the **Provider** dropdown, select **Private Cloud**.
6. In the search box below, select Windows and CentOS workstations.
7. At the bottom click the option **Individually select users** and select the users to assign to the workstations. 
    - **Note:** If assigning certain users to certain workstations, remove workstations under **Remote workstations to be added (x)**.
8. Click **Save**.

Note that it may take a 5-10 minutes for the workstation to show up in the **Select Remote Workstations** drop-down box.

### 9. Starting a PCoIP Session
Once the workstations have been added by Anyware Manager and assigned to Active Directory users, a user can connect through the PCoIP client using the domain name of the traffic manager: ```traffic-manager-domain-name```. 

1. Open the Teradici PCoIP Client and click on **NEW CONNECTION**.
2. Enter the public IP address of the Cloud Access Connector (CAC) virtual machine and enter a name for this connection. 
    - **Note**: If the ```traffic-manager-domain-name``` output does not show at the end of completion due to error it can be found on the Azure Portal. Select the ```traffic-manager``` and the **DNS name** will be shown on the top right.
3. Input the credentials from the account that was assigned under **User Entitlements for Workstations** from section 7 step 5. 
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations, close the PCoIP client and repeat steps 1-4.

### 10. Changing the deployment
Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run ```terraform apply``` again. Terraform will try to only apply the changes needed to acheive the new state.

Note that changes involving creating or recreating Cloud Access Connectors requires a new connector token from the Anyware Manager admin console. Create a new connector to obtain a new token.

### 11. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform. If this command doesn't delete everything entirely due to error, another alternative is to delete the resource group itself from the **Resource groups** page in Azure. 

### 12. Troubleshooting
- If the console looks frozen, try pressing Enter to unfreeze it.
- If no machines are showing up on Anyware Manager or get errors when connecting via PCoIP client, wait 2 minutes and retry. 
- If trying to run a fresh deployment and have been running into errors, delete all files containing  ```.tfstate```. These files store the state of the current infrastructure and configuration. 
- If there is a timeout error regarding **centos-gfx** machine(s) at the end of the deployment, this is because script extensions time out after 30 minutes. This happens sometimes but users can still add VMs to Anyware Manager.
    - As a result of this, there will be no outputs displaying on ACS. The IP address of the cac machine can be found by going into the deployment's resource group, selecting the machine ```[prefix]-cac-vm-0```, and the **Public IP address** will be shown on the top right.

Information about connecting to virtual machines for investigative purposes:
- CentOS and Windows VMs do not have public IPs. To connect to a **CentOS** workstations use the Connector (cac-vm) as a bastion host.
    1. SSH into the Connector. ```ssh <ad_admin_username>@<cac-public-ip>``` e.g.: ```cas_admin@52.128.90.145```
    2. From inside the Connector, SSH into the CentOS workstation. ```ssh centos_admin@<centos-internal-ip>``` e.g.: ```ssh centos_admin@10.0.4.5```
    3. The installation log path for CentOS workstations are located in ```/var/log/teradici/agent/install.log```. CAC logs are located in ```/var/log/teradici/cac-install.log```.

## Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
