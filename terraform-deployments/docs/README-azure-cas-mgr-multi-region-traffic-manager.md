# Anyware Manager (Multi Region Traffic Manager) Deployment

**Objective**: The objective of this documentation is to deploy the Anyware Manager Multi-Region Traffic Manager architecture on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS).

## Table of Contents
1. [Anyware Manager Multi Region Traffic Manager Architecture](#1-anyware-manager-multi-region-traffic-manager-architecture)
2. [Requirements](#2-requirements)
3. [Service Principal Authentication](#3-service-principal-authentication)
4. [Storing Secrets on Azure Key Vault](#4-optional-storing-secrets-on-azure-key-vault)
5. [Assigning a SSL Certificate](#5-optional-assigning-a-ssl-certificate)
6. [Deploying via Terraform](#6-deploying-via-terraform)
7. [Adding Workstations in Anyware Manager](#7-adding-workstations-in-anyware-manager)
8. [Starting a PCoIP Session](#8-starting-a-pcoip-session)
9. [Changing the deployment](#9-changing-the-deployment)
10. [Deleting the deployment](#10-deleting-the-deployment)
11. [Troubleshooting](#11-troubleshooting)

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:
- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)


### 1. Anyware Manager Multi Region Traffic Manager Architecture

The Anyware Manager Multi Region Traffic Manager deployment creates a Virtual Network with 4 subnets in the same region. The subnets created are:
- ```subnet-dc```: for the Domain Controller
- ```subnet-cac```: for the Connector
- ```subnet-ws```: for the workstations
- ```subnet-cas-mgr```: for the Anyware Manager

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes. Additional virtual networks will be created for each unique region.

A Domain Controller is created with Active Directory, DNS and LDAP-S configured. Domain Users are also created if a ```domain_users_list``` CSV file is specified. The Domain Controller is given a static IP.

Cloud Access Connectors are created and register themselves with the Anyware Manager.

Multiple domain-joined workstations and Cloud Access Connectors can be optionally created, specified by the the ```workstations``` variable. This is a list of objects where each object defines a workstation. These workstations are automatically domain-joined and have the PCoIP Agent installed.

The Traffic Manager is a global load balancer which distributes traffic between Cloud Access Connectors across regions. The client initiates a PCoIP session with the domain name of the Traffic Manager and selects one of the connectors to establish the connection. This deployments runs the Anyware Manager in a virtual machine which gives users full control of the Anyware deployment. The Anyware deployment will not have to reach out to the internet for Anyware management features, but the user is responsible for costs, security, updates, high availability and maintenance of the virtual machine running Anyware Manager.

The following diagram shows a deployment instance with one Cloud Access Connector and two workstations in each of the two regions: 

![cas_mgr_multi_region_diagram](/terraform-deployments/docs/png/multi-region-traffic-manager-azure.png)

### 2. Requirements
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### 3. Service Principal Authentication

In order for Terraform to deploy and manage resources on a user's behalf, it must authenticate through a service principal.

Run the deploy script via `. deploy.sh` in the Azure Cloud Shell, this will provide and set the required users Subscription and Tenant ID environment variables

**Note**: The user only needs to perform this step once to obtain a service principal. However, if the user already has a valid service principal but has forgotten the credential secret associated with it, they will need to delete the existing service principal and repeat this step again.  
After the service principal is created:
  1. If the user keep remaining in the current ACS session, please continue with the remaining steps.
  2. If the user manually or accidentally exits the current ACS session before the architecture is successfully deployed, they need to manually execute the following commands when a new ACS session starts:
     - export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
     - export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv) 

##### Option 1 (faster automated authentication):

The bash deploy script will automate the creation of a service principal and assign all of the required roles for deployment. Users will not be required to login via the Azure Portal

1. Upon completion of the deploy script, the Azure Cloud Shell will output the required Application ID and Client Secret which must be saved in the terraform.tfvars file
 ```
  {
  "appId": "xxxxxxxxxx",
  "displayName": "cas-mgr-one-ip-traffic-mgr",
  "password": "xxxxxxxxxx",
  "tenant": "xxxxxxxxxx"
  }
 ```
2. Open the terraform.tfvars file via `code terraform.tfvars` seen in section 6, step 3
3. Copy and paste the appId value into the application_id input field and the password value into the aad_client_secret input field
```
application_id                = "appId value here"
aad_client_secret             = "password value here"
```
4. The remaining information to be filled out includes providing the PCoIP Registration Code and all other desired workstation configurations. Save the file and skip to the remaining steps of deployment in section 6
**Note**: What if the Service Principal creation output values are lost or the Azure Cloud Shell times out?
In the instance that the Azure Cloud Shell times out or the output values are lost, the deploy script can be re-run and the previously created app and service principal will be patched and reset with a new client secret that users should update with. 
Otherwise, manual creation of the Service Principal and role assignments could be followed as seen by the steps in Option 2

##### Option 2 (slower manual authentication):

Running the deploy script will set the necessary environment variables for the User. Users are still able to manually authenticate via the Azure Portal using the following steps

1. Login to the [Azure portal](http://portal.azure.com/)
2. If not already open, from the dashboard open the left sidebar using the top-left button next to "Microsoft Azure". Click **Azure Active Directory**, then select **App registrations** from the "Manage" panel
3. Create a new application for the deployment by clicking **New registration**. If an application exists under **Owned applications**, this information can be reused.
   - More detailed information on how to create a Service Principal can be found directly through Microsoft Docs [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret). Navigate to the application overview by clicking on the registration name.
4. Copy and save the following information from the application overview:
   - **Application (client) ID** (required)
   - **Directory (tenant) ID** (optional; if you plan to use encrypted secrets through Azure Key Vault in [section 4](#4-optional-storing-secrets-on-azure-key-vault)
5. In the same page, on the left sidebar and in the "Manage" section, click **Certificates & secrets**
6. Create a new Client Secret or use an existing secret if you already know it. This value will only be shown once immediately after creation, make sure to save it
7. From the account dashboard, or using the search bar, go to **Subscriptions**. On the next page, select your subscription of choice
8. Navigate to the **Access control (IAM)** for this subscription
9. Click **+ Add**, and **Add role assignment** in the dropdown. Alternatively, select **Add role assignment** directly from the box titled "Grant access to this resource":
   1. Under **Role**, select the role **Contributor**. Click "Next"
   2. Under **Members**, leave the option on **User, group, or service principal**
   3. Select members to add the role to, searching up and clicking on the app registration name on the right side
   4. Review any details of interest, and click **Review + assign**
   5. Repeat this step for the role **Virtual Machine Contributor**

### 4. (Optional) Storing Secrets on Azure Key Vault

**Note**: This is optional. Users may skip this section and enter plaintext for the AD admin password, safe mode admin password, Anyware Manager admin password, and PCoIP registration key in terraform.tfvars.

As a security method to help protect the values listed above, users can store them as secrets in an Azure Key Vault. Secrets will be decrypted in the configuration scripts.

1. In the Azure portal, search for **Key Vault** and click **+ Add** to create a new key vault. 
    1. Select the same region as the deployment.
    2. Click next to go to the Access policy page.
    3. Click **+ Add Access Policy**.
        1. Under **Configure from template** select **Secret Management**.
        2. Under **Select principal** click on **None selected**.
        3. Find the application from [section 3](#3-service-principal-authentication) and click **Select**. The ID underneath should match the Client ID/Application ID saved from earlier.
        4. Click **Review + create** and then **Create**.
2. Click on the key vault that was created and click on **Secrets** inside the rightmost blade.
3. To create **AD safe mode admin password**, **AD admin password**, **CAS Manager admin password**, and **PCoIP registration key** as secrets follow these steps for each value:
    1. Click **+ Generate/Import**.
    2. Enter the name of the secret.
    3. Input the secret value.
    4. Click **Create**.
    5. Click on the secret that was created, click on the version and copy the **Secret Identifier**. 
      - **Tip**: To reduce the chance of errors, verify the secret is correct by clicking on **Show Secret Value**.
5. Fill in the following variables. Below is a completed example with tips underneath that can aid in finding the values.
```
# (Encryption is optional) Following 3 values and cac_token from cac_configuration can be encrypted. 
# To encrypt follow section 4 of the documentation.
ad_admin_password             = "https://mykeyvault.vault.azure.net/secrets/adPasswordID/123abcexample"
safe_mode_admin_password      = "https://mykeyvault.vault.azure.net/secrets/safeAdminPasswordID/123abcexample"
cas_mgr_admin_password        = "https://mykeyvault.vault.azure.net/secrets/casManagerPasswordID/123abcexample"
pcoip_registration_code       = "https://mykeyvault.vault.azure.net/secrets/pcoipSecretID/123abcexample"

# Used for authentication and allows Terraform to manage resources.
application_id                = "4928a0xd-e1re-592l-9321-5f114953d88c"
aad_client_secret             = "J492L_1KR2plr1SQdgndGc~gE~pQ.eR3F."

# Only fill these when using Azure Key Vault secrets.
# Examples and tips can be found in section 4 of the documentation.
# tenant_id                     = "31f56g8-1k3a-q43e-1r3x-dc340b62cf18"
# key_vault_id                  = "/subscriptions/12e06/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/mykeyvault"
# ad_pass_secret_name           = "adPasswordID"
```
- Tips for finding these variables:
    1. ```application_id``` and ```tenant_id``` are from [section 3](#3-service-principal-authentication) step 4.
    2. ```aad_client_secret```: This is the same secret from [section 3](#3-service-principal-authentication). If this secret is no longer saved, follow section 3 from steps 1-3 & 5-6 to obtain a new client secret.
    3. ```key_vault_id```: Go to the key vault containing the secrets on the Portal and click on **Properties** inside the opened blade. Copy the **Resource ID**.
    4. ```ad_pass_secret_name```: This is the name used for the ad pass secret. The name can be seen after```/secrets/``` from the variable ```ad_admin_password```. From the example above, this would be ```adPasswordID```.
    
### 5. (Optional) Assigning a SSL Certificate

**Note**: This is optional. Assigning a SSL certificate will prevent the PCoIP client from reporting an insecure connection when establishing a PCoIP session though users may still connect. Read more [here](https://www.teradici.com/web-help/anyware_manager/current/cloud_access_connector/certificate_cas_connector/). It is also an option to assign an SSL certificate **after** the completion of the script. More information can be found [here](https://www.teradici.com//web-help/anyware_manager/current/cloud_access_connector/cas_connector_update/#updating-ssl-certificates).

To upload a SSL certificate and SSL key onto ACS:
  1. Go into the **Resource group** that contains ACS storage. By default, the name should look like: **cloud-shell-storage-[region]**
  2. Click on the storage account being used for deployment.
  3. Next, click **File shares** and then click the file share that is mounted onto ACS.
  4. Upload the SSL certificate and SSL key. Must be in .pem format.
  5. The location of these files will be found in ```~/clouddrive/```
  6. Enter the paths to the SSL certificate and SSL key inside ```terraform.tfvars```.

### 6. Deploying via Terraform
terraform.tfvars is the file in which a user specifies variables for a deployment. The ```terraform.tfvars.sample``` sample file shows the required variables that a user must provide, along with other commonly used but optional variables. 

**Note**: Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

Before deploying, ```terraform.tfvars``` must be complete. 
1. Clone the repository into your Azure Cloud Shell (ACS) environment.
  - ```git clone https://github.com/teradici/Azure_Deployments```
2. Change directory into: ```/terraform-deployments/deployments/cas-mgr-one-ip-traffic-mgr```
  - ```cd Azure_Deployments/terraform-deployments/deployments/cas-mgr-one-ip-traffic-mgr```
3. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - To copy: ```cp terraform.tfvars.sample terraform.tfvars```
    - To configure: ```code terraform.tfvars```
    - To include optional variables, uncomment the line by removing preceding ```#```
    
    ```terraform.tfvars``` variables:

    1. workstation configuration:
        - ```prefix```: prefix added to workstation machines. e.g.: 'tera0' will name a standard Linux VM **tera0**-scent-0
            -   Must be a max of 5 characters to avoid name cropping. Can be left blank.
        - ```location```: location of the workstation. **westus** machines will be placed in the West US region. 
            -   Possible values: [Regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/). 
            -   **Note:** Ensure that there is 1 matching location in ```cac_location_list```
            -   e.g. West US 2 would be inputted as **westus2**. Central US as **centralus**.
        - ```workstation_os```: Operating system of the workstation.
            -   Possible values: **windows** or **linux**
        - ```vm_size```: Size of the virtual machine. 
            -   Possible values: [VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes). 
        - ```disk_type```: Type of storage for the workstation. 
            -   Possible values: **Standard_LRS**, **StandardSSD_LRS** or **Premium_LRS**
        - ```count```: Number of workstations to deploy under the specific settings.
        - ```isGFXHost```: Determines if a Grahpics Agent will be installed. Graphics agents require [**NV-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) or [**NCasT4_v3-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series). The default size in .tfvars is **Standard_NV12s_v3**. Additional VM sizes can be seen in the [**Appendix**](#appendix)
            -   Possible values: **true** or **false**
4. **(Optional)** To add domain users save `domain_users_list.csv.sample` as `domain_users_list.csv` and edit this file accordingly.

   Uncomment line#74 in "terraform.tfvars". The user must ensure the full path to the domain users list .csv file is correct. Otherwise, the provisioning script is not able to complete.
   - **Note:** To add users successfully, passwords must have atleast **3** of the following requirements:
     - 1 UPPERCASE letter
     - 1 lowercase letter
     - 1 number
     - 1 special character. e.g.: `!@#$%^&*()-_=+`
5. Run `terraform init` to initialize a working directory containing Terraform configuration files
6. Run `terraform apply | tee -a installer.log` to display resources that will be created by Terraform
   - **Note:** Users can also do `terraform apply` but often ACS will time out or there are scrolling limitations which prevents users from viewing all of the script output. `| tee -a installer.log` stores a local log of the script output which can be referred to later to help diagnose problems.
7. Answer `yes` to start provisioning the Anyware-M Multi-Region Traffic Manager infrastructure
   - To skip the need for this extra input, you can also initially use `terraform apply --auto-approve | tee -a installer.log`

A typical deployment should take around 35-40 minutes. When finished, the scripts will display VM information such as IP addresses. At the end of the deployment, the resources may still take a few minutes to start up completely. It takes a few minutes for a connector to sync with the Anyware Manager so **Health** statuses may show as **Unhealthy** temporarily.  

**Note:** During the deployment, if you don't interact with the Azure portal (for example click around), the Azure Cloud Shell (ACS) session may **time out**. In such cases, the deployment process will not continue once you reconnect to the ACS. You will need to delete the created resource group manually from the Azure portal and reconnect to ACS. Then, you must manually run the following two commands before applying the Terraform script again from the beginning to initiate a fresh deployment:
   - export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
   - export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv) 

Example output of successful deployment:
```
Apply complete! Resources: 106 added, 0 changed, 0 destroyed.

Outputs:

cas-mgr-public-ip = "123.345.678.92"
centos-gfx-internal-ip = {
  "gcent-0" = "10.0.4.5"
}
centos-std-internal-ip = {
  "scent-0" = "10.0.4.4"
}
domain-controller-internal-ip = "10.0.1.4"
domain-controller-public-ip = "123.345.678.93"
locations = [
  "westus2",
  "eastus",
]
resource_group = "cas_mgr_traffic_manager_e21a14"
traffic-manager-domain-name = "teradici.trafficmanager.net"
windows-gfx-internal-ip = {
  "gwin-0" = "10.0.4.6"
}
windows-std-internal-ip = {
  "swin-0" = "10.1.5.4"
}
```
    
### 7. Adding Workstations in Anyware Manager

To connect to workstations, the authorized users must be added to the machines, done through the Anyware Manager GUI.

Determine the public IP address of Anyware Manager Virtual Machine. This can be done by multiple methods including
- Through the output variables of a successful deployment
- Under the newly created resource group, opening the resource containing `cas-mgr-public-ip`, and inspecting the "IP address" field in the overview

1. In a browser, go to `https://<cas-mgr-public-ip>`.
2. Log in using the username `adminUser`, paired with the `cas_mgr_admin_password` specified in `terraform.tfvars`
   - Do not use the username specified in your variable file labelled `ad_admin_username`; the provided `adminUser` is the only provisioned one by default on deployment
3. Click **Workstations** on the left sidebar, click the blue **+** and select **Add existing remote workstation**.
4. From the **Provider** dropdown, select **Private Cloud**.
5. In the search box below, select the workstations to assign users to (i.e. Windows and CentOS workstations).
   - **Note:** You can remove workstations selected for assignment under **Remote workstations to be added (x)**.
7. At the bottom click the option **Individually select users** and select the users to assign to the workstations.
8. Click **Save**.

Note that it may take a 5-10 minutes for the workstation to show up in the **Select Remote Workstations** drop-down box.

### 8. Starting a PCoIP Session
Once the workstations have been added by Anyware Manager and assigned to Active Directory users, a user can connect through the PCoIP client using the domain name of the traffic manager: ```traffic-manager-domain-name```. 

1. Open the Teradici PCoIP Client and click on **NEW CONNECTION**.
2. Enter the domain name of the traffic manager and enter a name for this connection. 
    - **Note**: If the ```traffic-manager-domain-name``` output does not show at the end of completion due to error it can be found on the Azure Portal. Select the ```traffic-manager``` and the **DNS name** will be shown on the top right.
3. Input the credentials from the account that was assigned under **User Entitlements for Workstations** from section 7 step 5. 
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations, close the PCoIP client and repeat steps 1-4.

### 9. Changing the deployment
Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run ```terraform apply``` again. Terraform will try to only apply the changes needed to acheive the new state.

### 10. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform. If this command doesn't delete everything entirely due to error, another alternative is to delete the resource group itself from the **Resource groups** page in Azure. 

### 11. Troubleshooting
- If the console is frozen, try pressing Enter to unfreeze it. If freezing persists, a fresh deployment must be performed.
- If no machines are showing up on Anyware Manager or get errors when connecting via PCoIP client, wait 2 minutes and retry. 
- If trying to run a fresh deployment and have been running into errors, delete ```terraform.tfstate```. This file stores the state of the current infrastructure and configuration. Remember to also delete the previous deployment on the [Azure Portal](http://portal.azure.com/) if it's no longer being used.
- If for any reason there are no outputs displaying on ACS, the domain name of the traffic manager can be found by going onto the [Azure Portal](http://portal.azure.com/). Go into the deployment's resource group, select the traffic manager, and the **DNS name** will be shown on the top right.

Information about connecting to virtual machines for investigative purposes:
- CentOS and Windows VMs do not have public IPs. To connect to a **CentOS** workstations use the Connector (cac-vm) as a bastion host.
    1. SSH into the Connector. ```ssh <ad_admin_username>@<cac-public-ip>``` e.g.: ```cas_admin@52.128.90.145```
    2. From inside the Connector, SSH into the CentOS workstation. ```ssh centos_admin@<centos-internal-ip>``` e.g.: ```ssh centos_admin@10.0.4.5```
    3. The installation log path for CentOS workstations are located in ```/var/log/teradici/agent/install.log```. CAC logs are located in ```/var/log/teradici/cac-install.log```.  

  **Note**: SSH access is only allowed for your current ACS IP. if you exit the current ACS session and open another session, you won't be able to SSH into the connector because the IP of ACS changes each time the session is reconnected. In this case, you may need to manually add an inbound rule to your network security group (NSG) to allow traffic to port 22 from your IP (this is only for debug purpose). Please remember to delete your customized rule after debugging.
    
- To connect to a **Windows** workstations use the Domain Controller (dc-vm) as a bastion host. 
- **Note**: By default RDP is disabled for security purposes. Before running a deployment switch the **false** flag to **true** for the **create_debug_rdp_access** variable in **terraform.tfvars**. If there is already a deployment present go into the **Networking** settings for the dc-vm and click **Add inbound port rule**. Input **3389** in the **Destination port ranges** and click **Add**. Users should now be able to connect via RDP.
    1. RDP into the Domain Controller virtual machine. 
    
    ```
    Computer: <domain-controller-public-ip>
    User: cas_admin
    Password: <ad_admin_password from terraform.tfvars>
    ```
   2. From inside the Domain Controller, RDP into the Windows workstation. 
    
    ```
    Computer: <win-internal-ip>
    User: windows_admin
    Password: <ad_admin_password from terraform.tfvars>
    ```
   3. The installation log path for Windows workstations and DC machines are located in ```C:/Teradici/provisioning.log```.

## Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
