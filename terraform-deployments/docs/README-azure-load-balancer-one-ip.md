# Load Balancer (Multi-connector) Single IP Deployment

**Objective**: The objective of this documentation is to deploy the load balancer architecture on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS). 

## Table of Contents
1. [Load Balancer Single IP Architecture](#1-load-balancer-architecture)
2. [Requirements](#2-requirements)
3. [Connect Azure to Anyware Manager as a Service](#3-connect-azure-to-anyware-manager-as-a-service)
4. [Storing Secrets on Azure Key Vault](#4-optional-storing-secrets-on-azure-key-vault)
5. [Assigning a SSL Certificate](#5-optional-assigning-a-ssl-certificate)
6. [Deploying via Terraform](#6-deploying-via-terraform)
7. [Adding Workstations through Anyware Manager](#7-adding-workstations-through-anyware-manager)
8. [Starting a PCoIP Session](#8-starting-a-pcoip-session)
9. [Changing the deployment](#9-changing-the-deployment)
10. [Deleting the deployment](#10-deleting-the-deployment)
11. [Troubleshooting](#11-troubleshooting)
12. [Appendix](#12-appendix)

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:
- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)

### 1. Load Balancer Single IP Architecture

The Load Balancer deployment distributes traffic between Cloud Access Connectors within the same region. These connectors can be in different virtual networks as long as they're in the same region. The client initiates a PCoIP session with the public IP of the Load balancer, and the Load Balancer selects one of the connectors to establish the connection. In-session PCoIP traffic goes through the selected Cloud Access Connector directly, bypassing the HTTPS Load Balancer. 

Workstations and Cloud Access Connectors can be defined in the ```workstations``` and ```cac_configuration``` parameters respectively. Please refer to terraform.tfvars.sample for details.

The following diagram shows a load-balancer deployment instance with two Cloud Access Connectors and two workstations specified by the user:

![load-balancer diagram](/terraform-deployments/docs/png/load-balancer-azure.png)

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

A Domain Controller is created with Active Directory, DNS and LDAP-S configured. Domain Users are also created if a ```domain_users_list``` CSV file is specified. The Domain Controller is given a static IP (configurable).

A Cloud Access Connector is created and registers itself with the Anyware Manager service with the given Token and PCoIP Registration code.

Multiple domain-joined workstations and Cloud Access Connectors can be optionally created, specified by the following respective parameters:
- ```workstations```: List of objects, where each object defines a workstation
- ```cac_configuration```: List of objects, where each object defined a connector

The ```workstation_os``` property in the ```workstations``` parameter can be used to define the respective workstation's operating system (use 'linux' or 'windows'). 

Note: Please make sure that the ```location``` property in the ```workstations``` parameter is in sync with the ```location``` property defined in the ```cac_configuration``` parameter. 

Each workstation can be configured with a graphics agent by using the ```isGFXHost``` property of the ```workstations``` parameter.

These workstations are automatically domain-joined and have the PCoIP Agent installed.

### 2. Requirements
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- an Anyware Manager Deployment Service Account. Anyware Manager can be accessed [here](https://cas.teradici.com/)
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### 3. Connect Azure to Anyware Manager as a Service
This section configures the deployment so that it can be managed through Anyware Manager as a Service (Anyware-MAAS).

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
  "displayName": "single_connector_lls",
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
4. Login to Anyware Manager admin console [here](https://cas.teradici.com).
5. [Create](https://www.teradici.com/web-help/anyware_manager/current/admin_console/deployments/) a new deployment. **Note:** Steps 6 and 7 are optional. It allows for admins to turn on & off workstations from the Anyware Manager admin console.
6. Click on **Provider Service Accounts** and then **Azure**.
7. Submit the credentials into the [Azure form](https://www.teradici.com/web-help/anyware_manager/current/admin_console/deployments/#aws-cloud-credentials).
8. Click **Connectors** on the side bar and create a new connector.
9. Input a connector name to [generate](https://www.teradici.com//web-help/anyware_manager/current/cloud_access_connector/cas_connector_install/#generating-a-connector-token) a token. Tokens will be used in the .tfvars file. 
    - Load balancer deployment requires at least **2** unique tokens for cloud access connectors (cac). 
    - Tokens expire in 2 hours.
    - The value will be used inside ```terraform.tfvars``` like so: 
    ```
    cac_configuration : [
            { 
                cac_token: "vk315Gci2iJIdzLxT.. ", 
                location: "westus2" 
            },
            { 
                cac_token: "zpJ2bGciOmJdUzkfM.. ", 
                location: "westus2" 
            }
            ..
            ..
        ]
    ```
10. The remaining information to be filled out includes providing the PCoIP Registration Code and all other desired workstation configurations. Save the file and skip to the remaining steps of deployment in section 6
**Note**: What if the Service Principal creation output values are lost or the Azure Cloud Shell times out?
In the instance that the Azure Cloud Shell times out or the output values are lost, the deploy script can be re-run and the previously created app and service principal will be patched and reset with a new client secret that users should update with. 
Otherwise, manual creation of the Service Principal and role assignments could be followed as seen by the steps in Option 2

##### Option 2 (slower manual authentication):

Running the deploy script will set the necessary environment variables for the User. Users are still able to manually authenticate via the Azure Portal using the following steps

1. Login to the [Azure portal](http://portal.azure.com/)
2. Click **Azure Active Directory** in the left sidebar and click **App registrations** inside the opened blade.
3. Create a new application for the deployment by clicking **New registration**. If an application exists under **Owned applications**, this information can be reused. 
    - More information on how to create an App Registration can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
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
10. Login to Anyware Manager admin console [here](https://cas.teradici.com).
11. [Create](https://www.teradici.com/web-help/anyware_manager/current/admin_console/deployments/) a new deployment. **Note:** Steps 12 and 13 are optional. It allows for admins to turn on & off workstations from the Anyware Manager admin console.
12. Click on **Provider Service Accounts** and then **Azure**.
13. Submit the credentials into the [Azure form](https://www.teradici.com/web-help/anyware_manager/current/admin_console/deployments/#azure-cloud-credentials). 
14. Click **Connectors** on the side bar and create a new connector. 
15. Input a connector name to [generate](https://www.teradici.com/web-help/anyware_manager/current/cloud_access_connector/cas_connector_install/#generating-a-connector-token) a token. Tokens will be used in the .tfvars file. 
    - Load balancer deployment requires at least **2** unique tokens for cloud access connectors (cac). 
    - Tokens expire in 2 hours.
    - The value will be used inside ```terraform.tfvars``` like so: 
    ```
    cac_configuration : [
            { 
                cac_token: "vk315Gci2iJIdzLxT.. ", 
                location: "westus2" 
            },
            { 
                cac_token: "zpJ2bGciOmJdUzkfM.. ", 
                location: "westus2" 
            }
            ..
            ..
        ]
    ```

### 4. (Optional) Storing Secrets on Azure Key Vault

**Note**: This is optional. Users may skip this section and enter plaintext for the AD admin password, safe mode admin password, PCoIP registration key, and connector tokens in terraform.tfvars.

As a security method to help protect the AD safe mode admin password, AD admin password, PCoIP registration key, and connector tokens, users can store them as secrets in an Azure Key Vault. Secrets will be called and decrypted in the configuration scripts.

1. In the Azure portal, search for **Key Vault** and click **+ Add** to create a new key vault. 
    1. Select the same region as the deployment.
    2. Click next to go to the Access policy page.
    3. Click **+ Add Access Policy**.
        1. Under **Configure from template** select **Secret Management**.
        2. Under **Select principal** click on **None selected**.
        3. Find the application from [section 3](#3-connect-azure-to-anyware-manager-as-a-service) and click **Select**. The ID underneath should match the Client ID/Application ID saved from earlier.
        4. Click **Review + create** and then **Create**.
2. Click on the key vault that was created and click on **Secrets** inside the rightmost blade.
3. To create **AD safe mode admin password**, **AD admin password**, **PCoIP registration key**, and **connector token** as secrets follow these steps for each value:
    1. Click **+ Generate/Import**.
    2. Enter the name of the secret.
    3. Input the secret value.
    4. Click **Create**.
    5. Click on the secret that was created, click on the version and copy the **Secret Identifier**. 
      - **Tip**: To reduce the chance of errors, verify the secret is correct by clicking on **Show Secret Value**.
5. Fill in the following variables. Below is a completed example with tips underneath that can aid in finding the values.
```
...

cac_configuration : [
    { 
      cac_token: "https://mykeyvault.vault.azure.net/secrets/cacToken/e9d0204710d83e4d1e8b71a2d2a9c778", 
      location: "westus2" 
    },
    { 
      cac_token: "https://mykeyvault.vault.azure.net/secrets/cacToken/x9d0459710d83g4d1e8t74a2d2a9c097", 
      location: "westus2" 
    }
    ..
  ]

# (Encryption is optional) Following 3 values and cac_token from cac_configuration can be encrypted. 
# To encrypt follow section 4 of the documentation.
ad_admin_password             = "https://mykeyvault.vault.azure.net/secrets/adPasswordID/123abcexample"
safe_mode_admin_password      = "https://mykeyvault.vault.azure.net/secrets/safeAdminPasswordID/123abcexample"
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
    1. ```application_id``` and ```tenant_id``` are from [section 3](#3-connect-azure-to-cloud-access-manager) step 4.
    2. ```aad_client_secret```: This is the same secret from [section 3](#3-connect-azure-to-cloud-access-manager). If this secret is no longer saved, follow section 3 from step 1-3 & 5-6 to obtain a new client secret.
    3. ```key_vault_id```: Go to the key vault containing the secrets on the Portal and click on **Properties** inside the opened blade. Copy the **Resource ID**.
    4. ```ad_pass_secret_name```: This is the name used for the ad pass secret. The name can be seen after```/secrets/``` from the variable ```ad_admin_password```.

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

Detailed instructions can be viewed [here](/terraform-deployments/docs/terraform-config-step-by-step.md).

Note that the directory where this deployment, along with its corresponding `terraform.tfvars.sample` file, takes place is located under `Azure_Deployments/terraform-deployments/deployments/load-balancer-one-ip`.  

**Note:** During the deployment, if you don't interact with the Azure portal (for example click around), the Azure Cloud Shell (ACS) session may **time out**. In such cases, the deployment process will not continue once you reconnect to the ACS. You will need to delete the created resource group manually from the Azure portal and reconnect to ACS. Then, you must manually run the following two commands before applying the Terraform script again from the beginning to initiate a fresh deployment:
   - export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
   - export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv) 

### 7. Adding Workstations through Anyware Manager
It is recommended to add your Azure Provider Credentials to the Anyware Manager as to allow service interactions between them. This allows actions such as powering a remote workstation on or off. This can be done on the Anyware Manager dashboard, select **Add provider credentials**, select the **Provider Service Accounts** tab, and fill out the account credentials under Azure.

To connect to workstations, they have to be added through the Anyware Manager.
1. Go to the Anyware Manager admin console and ensure the correct deployment is selected. 
2. Click Workstations on the left sidebar, click the blue **+** and select **Add existing remote workstation**. 
3. From the **Provider** dropdown, select **Private Cloud** or **Azure**. If **Azure** is selected, select the name of the resource group of the deployment.
4. In the search box below, select Windows and CentOS workstations.
5. At the bottom click the option **Individually select users** and select the users to assign to the workstations. 
    - **Note:** If assigning certain users to certain workstations, remove workstations under **Remote workstations to be added (x)**.
6. Click **Save**.

Note that it may take a 5-10 minutes for the workstation to show up in the **Select Remote Workstations** drop-down box.

### 8. Starting a PCoIP Session
Once the workstations have been added to be managed by Anyware Manager and assigned to Active Directory users, users can connect through the PCoIP client using the public IP of the load balancer. 

1. Open the Teradici PCoIP Client and click on **NEW CONNECTION**.
2. Enter the IP address of the **Load Balancer** and enter a name for this connection. To connect to a specific CAC VM, enter the public IP address of the VM.
    - **Note**: If the ```load-balancer-public-ip``` output does not show at the end of completion due to error or script timeout it can be found on the Portal. Go into the **load balancer** resource and the **Public IP address** will be shown.
3. Input the credentials from the account that was assigned under **User Entitlements for Workstations** from section 7 step 5. 
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations, close the PCoIP client and repeat steps 1-4.

### 9. Changing the deployment
Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run ```terraform apply``` again. Terraform will try to only apply the changes needed to acheive the new state.

Note that changes involving creating or recreating Cloud Access Connectors requires a new connector token from the Anyware Manager admin console. Create a new connector to obtain a new token.

### 10. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform. If this command doesn't delete everything entirely due to error, another alternative is to delete the resource group itself from the **Resource groups** page in Azure. 

### 11. Troubleshooting
- If the console looks frozen, try pressing Enter to unfreeze it.
- If no machines are showing up on Anyware Manager or get errors when connecting via PCoIP client, wait 2 minutes and retry. 
- If trying to run a fresh deployment and have been running into errors, delete all files containing  ```.tfstate```. .tfstate files store the state of the current infrastructure and configuration. 
- If there is a timeout error regarding **centos-gfx** machine(s) at the end of the deployment, this is because script extensions time out after 30 minutes. This happens sometimes but users can still add VMs to CAM.

Information about connecting to virtual machines for investigative purposes:
- CentOS and Windows VMs do not have public IPs. To connect to a **CentOS** workstations use the Connector (cac-vm) as a bastion host.
    1. SSH into the Connector. ```ssh <ad_admin_username>@<cac-public-ip>``` e.g.: ```cas_admin@52.128.90.145```
    2. From inside the Connector, SSH into the CentOS workstation. ```ssh centos_admin@<centos-internal-ip>``` e.g.: ```ssh centos_admin@10.0.4.5```
    3. The installation log path for CentOS workstations are located in ```/var/log/teradici/agent/install.log```. CAC logs are located in ```/var/log/teradici/cac-install.log```.  

  **Note**: SSH access is only allowed for your current ACS IP. If you exit the current ACS session and open another session, you won't be able to SSH into the connector because the IP of ACS changes each time the session is reconnected. In this case, you may need to manually add an inbound rule to your network security group (NSG) to allow traffic to port 22 from your IP (this is only for debug purpose). Please remember to delete your customized rule after debugging.
    
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

### 12. Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
