# Anyware Manager (Single-Connector) Deployment

**Objective**: The objective of this documentation is to deploy the Anyware Manager Single-Connector architecture on Azure using [**Azure Cloud Shell**](https://portal.azure.com/#cloudshell/) (ACS). Please find deployment files [here](/terraform-deployments/deployments/cas-mgr-single-connector).

## Table of Contents

1. [Anyware Manager Single-Connector Architecture](#1-anyware-manager-single-connector-architecture)
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
12. [Videos](#12-videos)
13. [Appendix](#13-appendix)

For other Azure deployments, Amazon Web Services (AWS) deployments, and Google Cloud Platform (GCP) deployments:

- [Azure Deployments](https://github.com/teradici/Azure_Deployments)
- [AWS Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [GCP Deployments](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)


### 1. Anyware Manager Single-Connector Architecture

The Anyware Manager Single-Connector deployment creates a Virtual Network with 4 subnets in the same region, provided that the workstations defined in terraform.tfvars do not have distinct locations. The subnets created are:

- `subnet-dc`: for the Domain Controller
- `subnet-cac`: for the Connector
- `subnet-ws`: for the workstations
- `subnet-cas-mgr`: for the Anyware Manager

Network Security Rules are created to allow wide-open access within the Virtual Network, and selected ports are open to the public for operation and for debug purposes.

A Domain Controller is created with Active Directory, DNS and LDAP-S configured. Domain Users are also created if a `domain_users_list` CSV file is specified. The Domain Controller is given a static IP (configurable).

The Connector currently runs on an Ubuntu server, we are adding the support to run on Rocky Linux 8 or RHEL 8 starting from Connector version 22.04.0. The Cloud Access Connector is installed and configured on Ubuntu server, while the Anyware Connector is installed and configured on Rocky Linux 8 server.

A Cloud Access Connector\Anyware Connector is created and registers itself with the Anyware Manager service with the given token and PCoIP registration code.

Multiple domain-joined workstations and Cloud Access Connectors\Anyware Connector can be optionally created, specified by the the `workstations` variable. This is a list of objects where each object defines a workstation.

Note: Since this is a single region deployment, please make sure that all `location` values in the `workstations` parameter are all identical.

These workstations are automatically domain-joined and have the PCoIP Agent installed.

The following diagram shows a Anyware Manager single-connector deployment instance with multiple workstations and a single Cloud Access Connector deployed in the same region specified by the user. This deployments runs the Anyware Manager in a virtual machine which gives users full control of the Anyware deployment. The Anyware deployment will not have to reach out to the internet for Anyware management features, but the user is responsible for costs, security, updates, high availability and maintenance of the virtual machine running Anyware Manager.

![single-connector diagram](/terraform-deployments/docs/png/CASMSingleConnectorDC.png)

### 2. Requirements

- Access to a subscription on Azure, with permissions to create app registrations and role assignments
   - Alternatively, have access to some app registration on your subscription including its application ID and client secret
   - In order to create role assignments, you will need either "Owner" or "User Access Administrator" roles under your subscription
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html) or later
- [Azure Cloud Shell](https://shell.azure.com) access through the Azure portal
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/) (needs to be usable in Azure Cloud Shell)

### 3. Service Principal Authentication

In order for Terraform to deploy and manage resources on a user's behalf, it must authenticate through a service principal.

Run the deploy script via `. deploy.sh` in the Azure Cloud Shell, this will provide and set the required users Subscription and Tenant ID environment variables. **Note**: The deploy script could be found at `/Azure_Deployments/terraform-deployments/deployments/'Your-target-architecture'`

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
  "displayName": "cas-mgr-single-connector",
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

1. In the Azure portal, search for **Key vaults**. Navigate to the  and click **+ Create** for a new key vault.
   1. Select the same region as your intended deployment region (i.e. the region where your VMs are to be provisioned)
   2. Click next to go to the Access policy page.
   3. Click **+ Add Access Policy** (small link under "Permission Model").
      1. Under **Configure from template** select **Secret Management**.
      2. Under **Select principal** click on **None selected**.
      3. Find the application registration you created or used from [section 3](#3-service-principal-authentication) and click **Select**. The ID underneath should match the Client ID/Application ID saved from earlier.
      4. Click **Review + create** and then **Create**.
2. Click on the key vault that was created and click on **Secrets** under "Settings" inside the leftmost blade.
3. To create **AD safe mode admin password**, **AD admin password**, **CAS Manager admin password**, and **PCoIP registration key** as secrets follow these steps for each value:
   1. Click **+ Generate/Import**. Leave the upload option as "Manual"
   2. Enter a name for the secret
   3. Input your desired secret value
   4. Click **Create**
   5. Click on the secret that was created, click on the version and copy the **Secret Identifier**.
   - **Tip**: To reduce the chance of errors, verify the secret is correct by clicking on **Show Secret Value**.
4. Fill in the following variables, a completed example is shown below. Follow the tips underneath to help complete details regarding the Key vault. Note that the last 3 variables have been uncommented by removing the `#` at the beginning of their respective lines so that they will be used in deployment.

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
tenant_id                     = "31f56g8-1k3a-q43e-1r3x-dc340b62cf18"
key_vault_id                  = "/subscriptions/12e06/resourceGroups/keyvault/providers/Microsoft.KeyVault/vaults/mykeyvault"
ad_pass_secret_name           = "adPasswordID"
```

- Tips for finding these variables:
  1. `application_id` and `tenant_id` are from [section 3](#3-service-principal-authentication) step 4.
  2. `aad_client_secret`: This is the same secret from [section 3](#3-service-principal-authentication). If this secret is no longer saved, follow section 3 from steps 1-3 & 5-6 to obtain a new client secret.
  3. `tenant_id`: This can be found from the overview page of your desired Service Principal / App registration that you will be using for deployment. Copy the **Directory (tenant) ID** field to this variable
  4. `key_vault_id`: Go to the key vault containing the secrets on the Azure portal and click on **Properties** under "Settings" inside the opened blade. Copy the **Resource ID**.
  5. `ad_pass_secret_name`: This is the name used for the ad pass secret. The name can be seen after`/secrets/` from the variable `ad_admin_password`. From the example above, this would be `adPasswordID`.

### 5. (Optional) Assigning a SSL Certificate

**Note**: This is optional. Assigning a SSL certificate will prevent the PCoIP client from reporting an insecure connection when establishing a PCoIP session though users may still connect. Read more [here](https://www.teradici.com/web-help/anyware_manager/current/cloud_access_connector/certificate_cas_connector/). It is also an option to assign an SSL certificate **after** the completion of the script. More information can be found [here](https://www.teradici.com//web-help/anyware_manager/current/cloud_access_connector/cas_connector_update/#updating-ssl-certificates).

To upload a SSL certificate and SSL key onto ACS:

1. Go into the **Resource group** that contains ACS storage. By default, the name should look like: **cloud-shell-storage-[region]**
2. Click on the storage account being used for deployment.
3. Next, click **File shares** and then click the file share that is mounted onto ACS.
4. Upload the SSL certificate and SSL key. Must be in .pem format.
5. The location of these files will be found in `~/clouddrive/`
6. Enter the paths to the SSL certificate and SSL key inside `terraform.tfvars`.

### 6. Deploying via Terraform

terraform.tfvars is the file in which a user specifies variables for a deployment. The `terraform.tfvars.sample` sample file shows the required variables that a user must provide, along with other commonly used but optional variables.

**Note**: Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

Before deploying, `terraform.tfvars` must be complete.

1. Clone the repository into your Azure Cloud Shell (ACS) environment.

- `git clone https://github.com/teradici/Azure_Deployments`

2. Change directory into:

- Ubuntu server as Connector: `cd Azure_Deployments/terraform-deployments/deployments/cas-mgr-single-connector`
- Rocky Linux 8 server as Connector: `cd Azure_Deployments/terraform-deployments/deployments/cas-mgr-single-connector-rocky`

3. Save / rename `terraform.tfvars.sample` as `terraform.tfvars`, and fill out the required variables.

   - To copy: `cp terraform.tfvars.sample terraform.tfvars` or `mv terraform.tfvars.sample terraform.tfvars`
   - To open the file in Azure Cloud Shell, use: `code terraform.tfvars`
   - To include optional variables, uncomment the line by removing preceding `#`.
   - Make sure the locations of the connectors and work stations are identical.

   `terraform.tfvars` variables:

   1. workstation configuration:
      - `prefix`: prefix added to workstation machines. e.g.: 'tera0' will name a standard Linux VM **tera0**-scent-0
        - Must be a max of 5 characters to avoid name cropping. Can be left blank.
      - `location`: location of the workstation. **westus** machines will be placed in the West US region.
        - Possible values: [Regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/).
        - e.g. West US 2 will be inputted as **westus2**. Central US as **centralus**.
      - `workstation_os`: Operating system of the workstation.
        - Possible values: **windows** or **linux**
      - `vm_size`: Size of the virtual machine.
        - Possible values: [VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).
      - `disk_type`: Type of storage for the workstation.
        - Possible values: **Standard_LRS**, **StandardSSD_LRS** or **Premium_LRS**
      - `count`: Number of workstations to deploy under the specific settings.
      - `isGFXHost`: Determines if a Graphics Agent will be installed. Graphics agents require [**NV-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) or [**NCasT4_v3-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series). The default size in .tfvars is **Standard_NV12s_v3**. Additional VM sizes can be seen in the [**Appendix**](#appendix)
        - Possible values: **true** or **false**

   The remaining variables have their descriptions included in the provided sample file.

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
7. Answer `yes` to start provisioning the infrastructure. 
   - To skip the need for this extra input, you can also initially use `terraform apply --auto-approve | tee -a installer.log`

A typical deployment should take around 35-40 minutes. When finished, the scripts will display VM information such as IP addresses. At the end of the deployment, the resources may still take a few minutes to start up completely. It takes a few minutes for a connector to sync with the Anyware Manager so **Health** statuses may show as **Unhealthy** temporarily.  

**Note:** During the deployment, if you don't interact with the Azure portal (for example click around), the Azure Cloud Shell (ACS) session may **time out**. In such cases, the deployment process will not continue once you reconnect to the ACS. You will need to delete the created resource group manually from the Azure portal and reconnect to ACS. Then, you must manually run the following two commands before applying the Terraform script again from the beginning to initiate a fresh deployment:
   - export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
   - export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv) 

Example output of successful deployment:

```
Apply complete! Resources: 67 added, 0 changed, 0 destroyed.

Outputs:

cac-public-ip = [
  [
    "public_ip" = "52.109.24.176"
  ],
]
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
domain-controller-private-ip = "10.0.1.4"
domain-controller-public-ip = "52.109.24.161"
resource_group = "single_connector_deployment_c4fe3"
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

Once the workstations have been added by Anyware Manager and assigned to Active Directory users, a user can connect through the PCoIP client using the public IP of the Cloud Access Connector. This can be found through the end of deployment outputs on success.
   - **Note**: If you need to find the `public_ip` of the `cac-public-ip` output after it has gone away, it can be found on the Azure Portal. Select the machine `[prefix]-cac-vm-0` and the **Public IP address** will be shown.

1. Open the Teradici PCoIP Client and click on **NEW CONNECTION**.
2. Enter the public IP address of the Cloud Access Connector (CAC) virtual machine and enter a name for this connection. Select **SAVE** and then **NEXT**
3. Input the credentials from the account that was assigned under **User Entitlements for Workstations** from section 7 step 5.
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations, close the PCoIP client and repeat steps 1-4.

### 9. Changing the deployment

Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run `terraform apply` again. Terraform will try to only apply the changes needed to acheive the new state.

### 10. Deleting the deployment

Run `terraform destroy -force` to remove all resources created by Terraform. If this command doesn't delete everything entirely due to error, another alternative is to delete the resource group itself from the **Resource groups** page in Azure.

### 11. Troubleshooting

- If the console looks frozen, try pressing Enter to unfreeze it.
- If no machines are showing up on Anyware Manager or get errors when connecting via PCoIP client, wait 2 minutes and retry.
- If you are trying to create a fresh deployment and have been running into errors, delete all files containing `.tfstate`. These files store the state of the current infrastructure and configuration

- If there is a timeout error regarding **centos-gfx** machine(s) at the end of the deployment, this is because script extensions time out after 30 minutes. This happens sometimes but users can still add VMs to Anyware Manager.
  - As a result of this, there will be no outputs displaying on ACS. The IP address of the cac machine can be found by going into the deployment's resource group, selecting the machine `[prefix]-cac-vm-0`, and the **Public IP address** will be shown on the top right.

- When logging into the Anyware Manager web UI, if you come across a message stating **Ad configuration not found**, be sure to log in using the default username `adminUser`

Connecting to virtual machines for investigative purposes:

- CentOS and Windows VMs do not have public IPs. To connect to a **CentOS** workstation use the Connector (cac-vm) as a bastion host.
  1. SSH into the Connector. `ssh <ad_admin_username>@<cac-public-ip>` e.g.: `cas_admin@52.128.90.145`
  2. From inside the Connector, SSH into the CentOS workstation. `ssh centos_admin@<centos-internal-ip>` e.g.: `ssh centos_admin@10.0.4.5`
  3. The installation log path for CentOS workstations are located in `/var/log/teradici/agent/install.log`. CAC logs are located in `/var/log/teradici/cac-install.log`.  

  **Note**: SSH access is only allowed for your current ACS IP. if you exit the current ACS session and open another session, you won't be able to SSH into the connector because the IP of ACS changes each time the session is reconnected. In this case, you may need to manually add an inbound rule to your network security group (NSG) to allow traffic to port 22 from your IP (this is only for debug purpose). Please remember to delete your customized rule after debugging.

- To connect to a **Windows** workstations use the Domain Controller (dc-vm) as a bastion host.
- **Note**: By default RDP is disabled for security purposes. Before running a deployment switch the **false** flag to **true** for the **create_debug_rdp_access** variable in **terraform.tfvars**. If there is already a deployment present go into the **Networking** settings for the dc-vm and click **Add inbound port rule**. Input **3389** in the **Destination port ranges** and click **Add**. Users should now be able to connect via RDP.
  1. RDP into the Domain Controller virtual machine.
  ```
  Computer: <domain-controller-public-ip>
  User: cas_admin
  Password: <ad_admin_password from terraform.tfvars>
  ```
  2.  From inside the Domain Controller, RDP into the Windows workstation.
  ```
  Computer: <win-internal-ip>
  User: windows_admin
  Password: <ad_admin_password from terraform.tfvars>
  ```
  3.  The installation log path for Windows workstations and DC machines are located in `C:/Teradici/provisioning.log`.
  
- If ACS times out and takes all the terraform logs with it, you can set it up before you deploy with `terraform apply`. Terraform depends on two environment variables being configured:
   -  `TF_LOG` which is one of DEBUG, INFO, WARN, ERROR, TRACE
   -  `TF_LOG_PATH` sets the path and file where logs will be stored (e.g. terraformLogs.txt)

  - PowerShell:
  ```
    $env:TF_LOG="TRACE"
    $env:TF_LOG_PATH="terraformLogs.txt"
  ```
  - Bash:

  ```
    export TF_LOG="TRACE"
    export TF_LOG_PATH="terraformLogs.txt"
  ```

### 12. Videos
A video of the deployment process for this terraform can be found on [Teradici's Youtube channel](https://www.youtube.com/watch?v=GiAWP1KdvTc). Note that the process to add a role assignment to a subscription has changed slightly, as detailed in [section 3.9](#3-service-principal-authentication).

### 13. Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
