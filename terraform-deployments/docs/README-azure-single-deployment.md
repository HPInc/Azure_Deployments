# Single-Connector Deployment

**Learning Objective**: The objective of this script is to automate the deployment of the single-connector architecture. This document is a guide on how to deploy a single-connector deployment on Azure from **Azure Cloud Shell** (ACS). 

We also support deployments on Amazon Web Services (AWS) and Google Cloud Platform (GCP).
- For AWS deployments click [here](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md).
- For GCP deployments click [here](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md).

## Table of Contents
1. [Single-Connector Architecture](#1-single-connector-architecture)
2. [Requirements](#2-requirements)
3. [Connect Azure to Cloud Access Manager](#3-connect-azure-to-cloud-access-manager)
4. [Storing Secrets on Azure Key Vault](#4-optional-storing-secrets-on-azure-key-vault)
5. [Deploying the Single-Connector via Terraform](#5-deploying-the-single-connector-via-terraform)
6. [Adding Workstations in Cloud Access Manager](#6-adding-workstations-in-cloud-access-manager)
7. [Starting a PCoIP Session](#7-starting-a-pcoip-session)
8. [Changing the deployment](#8-changing-the-deployment)
9. [Deleting the deployment](#9-deleting-the-deployment)
10. [Troubleshooting](#10-troubleshooting)

### 1. Single-Connector Architecture

The Single-Connector deployment creates a Virtual Network with 3 subnets in the same region, provided that the workstations defined in terraform.tfvars do not have distinct locations. The subnets created are:
- ```subnet-dc```: for the Domain Controller
- ```subnet-cac```: for the Connector
- ```subnet-ws```: for the workstations

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

A Domain Controller is created with Active Directory, DNS and LDAP-S configured. Domain Users are also created if a ```domain_users_list``` CSV file is specified. The Domain Controller is given a static IP (configurable).

A Cloud Access Connector is created and registers itself with the CAM service with the given Token and PCoIP Registration code.

Multiple domain-joined workstations and Cloud Access Connectors can be optionally created, specified by the following respective parameters:
- ```workstations```: List of objects, where each object defines a workstation
- ```cac_configuration```: List of objects, where each object defined a connector

The ```workstation_os``` property in the ```workstations``` parameter can be used to define the respective workstation's operating system (use 'linux' or 'windows'). 

Note: Please make sure that the ```location``` property in the ```workstations``` parameter is in sync with the ```location``` property defined in the ```cac_configuration``` parameter. 

Each workstation can be configured with a graphics agent by using the ```isGFXHost``` property of the ```workstations``` parameter.

These workstations are automatically domain-joined and have the PCoIP Agent installed.

The following diagram shows a single-connector deployment instance with multiple workstations and a single Cloud Access Connector deployed in the same region specified by the user. 

![single-connector diagram](single-connector-azure.PNG)

### 2. Requirements
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- a Cloud Access Manager Deployment Service Account. CAM can be accessed [here](https://cam.teradici.com/)
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### 3. Connect Azure to Cloud Access Manager
To interact directly with remote workstations, an Azure Account must be connected to the Cloud Access Manager.
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
10. Login to Cloud Access Manager Admin Console [here](https://cam.teradici.com).
11. [Create](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/deployments/) a new deployment. **Note:** Steps 12 and 13 are optional. It allows for admins to turn on & off workstations from the Cloud Acess Manager console.
12. Click on **Cloud Service Accounts** and then **Azure**.
13. Submit the credentials into the [Azure form](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/deployments/#azure-cloud-credentials). 
14. Click **Connectors** on the side bar and create a new connector. 
15. Input a connector name to [generate](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/obtaining_connector_token_install/) a token. Save this as it will be used later. 
    - This token expires in 2 hours. 
    - The value will be used inside ```terraform.tfvars``` like so: 
    ```
    cac_configuration : [
            { 
                cac_token: "token_here", 
                location: "westus2" 
            }
        ]
    ```

### 4. (Optional) Storing Secrets on Azure Key Vault

**Note**: This is optional. You may skip this section and enter plaintext for your AD admin password, safe mode admin password, PCoIP registration key, and connector token in terraform.tfvars.

As a security method to help protect your AD safe mode admin password, AD admin password, PCoIP registration key, and connector token, you can store them as secrets in an Azure Key Vault. Secrets will be called and decrypted in the configuration scripts. To use secrets from the Azure Key Vault you will need to do configuration following the instructions below:

1. In the Azure portal, search for **Key Vault** and click **+ Add** to create a new key vault. 
    1. Select the same region as your deployment.
    2. Click next to go to the Access policy page.
    3. Click **+ Add Access Policy**.
        1. Under **Configure from template** select **Secret Management**.
        2. Under **Select principal** click on **None selected**.
        3. Find the application from [section 3](#3-connect-azure-to-cloud-access-manager) and click **Select**. The ID underneath should match the Client ID/Application ID you saved from earlier.
        4. Click **Review + create** and then **Create**.
2. Click on the key vault that was created and click on **Secrets** inside the rightmost blade.
3. To create **AD safe mode admin password**, **AD admin password**, **PCoIP registration key**, and **connector token** as secrets follow these steps for each value:
    1. Click **+ Generate/Import**.
    2. Enter the name of your secret.
    3. Input the secret value.
    4. Click **Create**.
    5. Click on the secret that was created, click on the version and copy the **Secret Identifier**.
5. Fill in the following variables from this completed example. There are tips underneath that can aid in finding the values.
```
...

cac_configuration : [
    { 
      cac_token: "https://mykeyvault.vault.azure.net/secrets/cacToken/e9d0204710d83e4d1e8b71a2d2a9c778", 
      location: "westus2" 
    }
  ]

# (Encryption is optional) Following 3 values and cac_token from cac_configuration can be encrypted. 
# To encrypt follow section 4 of the documentation.
ad_admin_password             = "Password!234"
safe_mode_admin_password      = "Password!234"
pcoip_registration_code       = "ABCDEFGHIJKL@0123-4567-89AB-CDEF"

# Used for authentication and allows Terraform to manage resources.
application_id                = "<from section 3 step 4>"
aad_client_secret             = "<from section 3 step 5-6>"

# Only fill these when using Azure Key Vault secrets.
# Examples and tips can be found in section 4 of the documentation.
# tenant_id                     = "<from section 3 step 4>"
# key_vault_id                  = "<found in key vault properties under Resource ID>"
# ad_pass_secret_name           = "<variable name used for ad pass secret>"
```
- Tips for finding these variables:
    1. ```application_id``` and ```tenant_id``` are from [section 3](#3-connect-azure-to-cloud-access-manager) step 4.
    2. ```aad_client_secret```: This is the same secret from [section 3](#3-connect-azure-to-cloud-access-manager). If you no longer have this, follow section 3 from step 1-3 & 5-6 to obtain a new client secret.
    2. ```key_vault_id```: Go to your key vault and click on **Properties** inside the opened blade. Copy the **Resource ID**.
    3. ```ad_pass_secret_name```: This is the name you used for the ad pass secret. The name can be seen after```/secrets/``` from the variable ```ad_pass_secret_id```.

### 5. Deploying the Single-Connector via Terraform
terraform.tfvars is the file in which a user specifies variables for a deployment. The ```terraform.tfvars.sample``` sample file shows the required variables that a user must provide, along with other commonly used but optional variables. 

**Note**: Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

Before the deployment of the single-connector, ```terraform.tfvars``` and ```domain_users_list.csv``` must be complete. 
1. Change directory into: ```/terraform-deployments/deployments/single-connector```.
2. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - Users can edit files inside ACS by doing ```code terraform.tfvars```.
    - The resource group name must be unique and must not already exist.
    - Make sure the locations of the connectors and work stations are identical.
    - Graphics agents require the [**NV-series**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) instance types which use M60 GPUs. We suggest using ```"Standard_NV6"``` as the ```"vm_size"``` for graphics workstations.
3. Save ```domain_users_list.csv.sample``` as ```domain_users_list.csv``` and add domain users.
    - **Note:** To add users successfully, passwords must have atleast **3** of the following requirements:
      - 1 UPPERCASE letter
      - 1 lowercase letter
      - 1 number
      - 1 special character. e.g.: ```!@#$%^&*(*))_+```
4. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
5. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
    - **Note:** Users can also do ```terraform apply``` but often ACS will time out or there are scrolling limitations which prevents users from viewing all of the script output. ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose problems.
6. Answer ```yes``` to start provisioning the single-connector infrastructure. 

A typical deployment should take around 30-40 minutes. When finished, the scripts will display VM information such as IP addresses. At the end of the deployment, the resources may still take a few minutes to start up completely. Connectors should register themselves with the CAM service and show up in the CAM Admin Console.

Example output:
```
Apply complete! Resources: 67 added, 0 changed, 0 destroyed.

Outputs:

cac-vms = [
  {
    "name" = "ter3-cac-vm-0"
    "private_ip" = "10.0.3.4"
    "public_ip" = "52.109.24.176"
  },
]
centos-graphics-workstations = [
  {
    "name" = "ter0-gcent-0"
    "private_ip" = "10.0.4.5"
    "public_ip" = ""
  },
]
centos-standard-workstations = [
  {
    "name" = "ter0-scent-0"
    "private_ip" = "10.0.4.6"
    "public_ip" = ""
  },
]
domain-controller-private-ip = "10.0.1.4"
domain-controller-public-ip = "52.109.24.161"
locations = [
  "westus2",
]
resource_group = "my-single-connector-deployment"
windows-standard-workstations = [
  {
    "name" = "ter0-swin-0"
    "private_ip" = "10.0.4.4"
    "public_ip" = ""
  },
]
windows-graphics-workstations = [
  {
    "name" = "ter0-gwin-0"
    "private_ip" = "10.0.4.7"
    "public_ip" = ""
  },
]
```
    
### 6. Adding Workstations in Cloud Access Manager
To connect to workstations, they have to be added through the Cloud Access Manager. 
1. Go to the CAM Admin Console and ensure you have your deployment selected. 
2. Click Workstations on the right sidebar, click the blue **+** and select **Add existing remote workstation**. 
3. From the **Provider** dropdown, select **Private Cloud** or **Azure**. If **Azure** is selected, select the name of your resource group declared in terraform.tfvars.
4. In the search box below, select Windows and CentOS workstations.
5. At the bottom click the option **Individually select users** and select the users you would like to assign to the workstations. 
    - **Note:** If you would like to assign certain users to certain workstations you can remove workstations under **Remote workstations to be added (x)**.
6. Click **Save**.

Note that it may take a 5-10 minutes for the workstation to show up in the **Select Remote Workstations** drop-down box.

### 7. Starting a PCoIP Session
Once the workstations have been added to be managed by CAM and assigned to Active Directory users, a user can connect through the PCoIP client using the public IP of the Cloud Access Connector.

1. Open the Teradici PCoIP Client and click on **NEW CONNECTION**.
2. Enter the public IP address of the Cloud Access Connector (CAC) virtual machine and enter a name for this connection. 
3. Input the credentials from the account that was assigned under **User Entitlements for Workstations** in CAM.
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations, close the PCoIP client and repeat steps 1-4.

### 8. Changing the deployment
Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run ```terraform apply``` again. Terraform will try to only apply the changes needed to acheive the new state.

Note that changes involving creating or recreating Cloud Access Connectors requires a new connector token from the CAM Admin Console. Create a new connector to obtain a new token.

### 9. Deleting the deployment
Run ```terraform destroy -force``` to remove all resources created by Terraform. If this command doesn't delete everything entirely due to error, another alternative is to delete the resource group itself from the **Resource groups** page in Azure. 

### 10. Troubleshooting
- If the console looks frozen, try pressing Enter to unfreeze it.
- If the script fails you can try rerunning the deployment again using ```terraform apply | tee -a installer.log```.
- If you are trying to run a fresh deployment and have been running into errors, you may need to delete all files containing  ```.tfstate```. .tfstate files store the state of your current infrastructure and configuration. 

Information about connecting to virtual machines for investigative purposes:
- CentOS and Windows VMs do not have public IPs. To connect to a **CentOS** workstations use the Connector (cac-vm) as a bastion host.
    1. SSH into the Connector. ```ssh <ad_admin_username>@<cac-public-ip>``` e.g.: ```cam_admin@52.128.90.145```
    2. From inside the Connector, SSH into the CentOS workstation. ```ssh <ad_admin_username>@<centos-internal-ip>``` e.g.: ```ssh cam_admin@10.0.4.5```
    3. The installation log path for CentOS workstations are located in ```/var/log/teradici/agent/install.log```. CAC logs are located in ```/var/log/teradici/cac-install.log```.
    
- To connect to a **Windows** workstations use the Domain Controller (dc-vm) as a bastion host. 
- **Note**: By default RDP is disabled for security purposes. Before running a deployment switch the **false** flag to **true** for the **create_debug_rdp_access** variable in **terraform.tfvars**. If there is already a deployment present go into the **Networking** settings for the dc-vm and click **Add inbound port rule**. Input **3389** in the **Destination port ranges** and click **Add**. You should now be able to connect via RDP.
    1. RDP into the Domain Controller virtual machine. 
    
    ```
    Computer: <domain-controller-public-ip>
    User: cam_admin
    Password: <ad_admin_password_set_in_terraform.tfvars>
    ```
   2. From inside the Domain Controller, RDP into the Windows workstation. 
    
    ```
    Computer: <win-internal-ip>
    User: cam_admin
    Password: <ad_admin_password_set_in_terraform.tfvars>
    ```
   3. The installation log path for Windows workstations and DC machines are located in ```C:/Teradici/provisioning.log```.
