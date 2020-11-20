# Single-Connector Deployment

**Learning Objective**: The objective of this script is to automate the deployment of the single-connector architecture. This document is a guide on how to deploy a single-connector deployment on Azure from **Azure Cloud Shell** (ACS). 

## Table of Contents
1. [Single-Connector Architecture](#single-connector-architecture)
2. [Requirements](#requirements)
3. [Connect Azure to Cloud Access Manager](#connect-azure-to-cloud-access-manager)
4. [Deploying Azure Storage Account](#deploying-azure-storage-account)
5. [Deploying the Single-Connector via Terraform](#deploying-the-single-connector-via-terraform)
6. [Adding Workstations in Cloud Access Manager](#adding-workstations-in-cloud-access-manager)
7. [Starting a PCoIP Session](#starting-a-pcoip-session)
8. [Changing the deployment](#changing-the-deployment)
9. [Deleting the deployment](#deleting-the-deployment)
10. [Troubleshooting](#troubleshooting)

### Single-Connector Architecture

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

### Requirements
- Access to a subscription on Azure.
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- a Cloud Access Manager Deployment Service Account. CAM can be accessed [here](https://cam.teradici.com/)
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/)

### Connect Azure to Cloud Access Manager
To interact directly with remote workstations, an Azure Account must be connected to the Cloud Access Manager.
1. Login to the [Azure portal](http://portal.azure.com/)
2. Click Azure Active Directory in the left sidebar and click app registrations inside the opened blade.
3. Create a new application for the deployment by clicking 'New registration'. If an application exists under 'Owned applications', this information can be reused. 
    - More information on how to create an App Registration can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#create-a-new-application-secret).
4. Copy the following information from the application overview: 
    - Client ID
    - Tenant ID
    - Object ID
5. Under the same app, click Certificates & secrets.
6. Create a new Client Secret or use an existing secret. This value will only be shown once, make sure to save it.
7. Go to Subscriptions by searching 'subscription' into the search bar and click on the subscription of choice.
8. Copy the Subscription ID and click on Access control (IAM) on the blade. 
9. Click 'Add', select 'Add role assignment' and follow these steps to add roles:
    1. Under 'Role' select 'Reader'.
    2. Leave 'Assign access to' as default.
    3. Under 'Select' search for the application name from step 4 and click save.
    4. Repeat these steps for the role 'Virtual Machine Contributor'.
10. Login to Cloud Access Manager Admin Console [here](https://cam.teradici.com) using a Microsoft business account.
11. [Create](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/deployments/) a new deployment and submit the credentials into the [Azure form](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/deployments/#azure-cloud-credentials). 
12. Click 'Connectors' on the side bar and create a new connector. 
13. Input a connector name to [generate](https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/cam_admin_console/obtaining_connector_token_install/) a token. Save this as it will be used in terraform.tfvars. **Note:** This token expires in 2 hours.

### Deploying Azure Storage Account
The purpose of deploying an Azure Storage Account is to store scripts on cloud storage so that they can be obtained through a Uniform Resource Identifier (URI). Inside the Windows and CentOS workstations, these scripts are downloaded via the URI and executed to configure PCoIP.

To complete the ```terraform.tfvars``` file in the next section, an Azure Storage Account must be created.

[![Launch Cloud Shell](https://shell.azure.com/images/launchcloudshell.png "Launch Cloud Shell")](https://shell.azure.com)

1. Clone this GitHub repository using: ```git clone https://github.com/teradici/Azure_deployments```.
2. Next, change directory: ```cd ~/Azure_deployments/terraform-deployments/tools/deploy-script-storage-account```
3. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
4. Run ```terraform apply``` to start the creation of the Azure Storage Account. 
    1. Users will be asked for a name for a new resource group for this storage. **Note**: This resource group name is unique and seperate from what is in .tfvars.
    2. Users will then be asked for a name for the storage account itself. **Note**: Only lowercase letters and numbers are accepted. 
5. Answer ```yes``` to start the creation of the Azure Storage Account. 
6. A storage URI will be generated. Save this, it will be used in the next section as a value for the _artifactsLocation variable in terraform.tfvars.

Example output:
``` 
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

_artifactsLocation = https://mystorage.blob.core.windows.net/mystoragecontainer/
resource_group_name = My-Resource-Group
storage_account_name = mystorage
```

### Deploying the Single-Connector via Terraform
terraform.tfvars is the file in which a user specifies variables for a deployment. The ```terraform.tfvars.sample``` sample file shows the required variables that a user must provide, along with other commonly used but optional variables. Uncommented lines show required variables, while commented lines show optional variables with their default or sample values. A complete list of available variables are described in the variable definition files ```default-vars.tf``` and ```required-vars.tf``` of the deployment.

Before the deployment of the single-connector, ```terraform.tfvars``` and ```domain_users_list.csv``` must be complete. 
1. Change directory into: ```~/Azure_deployments/terraform-deployments/deployments/single-connector```.
2. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - Users can edit files inside ACS by doing ```code terraform.tfvars```.
    - Make sure the locations of the connectors and work stations are identical.
3. Save ```domain_users_list.csv.sample``` as ```domain_users_list.csv``` and add domain users.
4. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
5. Run ```terraform apply >> installer.log``` to display resources that will be created by Terraform. ```>> installer.log``` stores a local log of the script output. 
6. Answer ```yes``` to start provisioning the single-connector infrastructure. 

A typical deployment should take around 45 minutes. When finished, the scripts will display VM information such as IP addresses. At the end of the deployment, the resources may still take a few minutes to start up completely. Connectors should register themselves with the CAM service and show up in the CAM Admin Console.

Example output:
```
Apply complete! Resources: 57 added, 0 changed, 0 destroyed.

Outputs:

cac-vms = [
  {
    "id" = "/subscriptions/1234/resourceGroups/My-RG/providers/Microsoft.Compute/virtualMachines/tera-cac-vm-0"
    "location" = "westus2"
    "name" = "tera-cac-vm-0"
    "private_ip" = "10.0.3.4"
    "public_ip" = "12.34.567.890"
    "size" = "Standard_D2s_v3"
  },
]
domain-controller-group = My-RG
domain-controller-private-ip = 10.0.1.4
domain-controller-public-ip = 12.34.567.892
linux-workstations = [
  {
    "id" = "/subscriptions/1234/resourceGroups/My-RG/providers/Microsoft.Compute/virtualMachines/centos-host-0"
    "location" = "westus2"
    "name" = "centos-host-0"
    "private_ip" = "10.0.4.4"
    "public_ip" = "12.34.56.800"
]
locations = [
  "westus2",
]
windows-workstations = [
  {
    "id" = "/subscriptions/1234/resourceGroups/My-RG/providers/Microsoft.Compute/virtualMachines/windows-host-0"
    "location" = "westus2"
    "name" = "windows-host-0"
    "private_ip" = "10.0.4.5"
    "public_ip" = "12.34.567.835"
    "size" = "Standard_B2ms"
  },
]
```

### Adding Workstations in Cloud Access Manager
To connect to workstations, they have to be added through the Cloud Access Manager. 
1. Go to the CAM Admin Console and ensure you have your deployment selected. 
2. Click Workstations on the right sidebar, click the blue '+' and select "Add existing remote workstation". 
3. Select 'Private Cloud' or 'Azure' with the name of your resource group declared in terraform.tfvars.
4. Under 'Remote Workstations' select the Windows and CentOS host machines.
5. Under 'User Entitlements for Workstations' add the Active Directory username declared in terraform.tfvars.

Note that it may take a 5-10 minutes for the workstation to show up in the 'Select Remote Workstations' drop-down box.

### Starting a PCoIP Session
Once the workstations have been added to be managed by CAM and assigned to Active Directory users, a user can connect through the PCoIP client using the public IP of the Cloud Access Connector.

1. Open the Teradici PCoIP Client and click on 'NEW CONNECTION'.
2. Enter the public IP address of the Cloud Access Connector (CAC) virtual machine and enter a name for this connection. 
3. Input the credentials from the account that was assigned under 'User Entitlements for Workstations' in CAM.
4. Click on a machine to start a PCoIP session.
5. To connect to different workstations repeat steps 1-4.

### Changing the deployment
Terraform is a declarative language to describe the desired state of resources. A user can modify terraform.tfvars and run ```terraform apply``` again. Terraform will try to only apply the changes needed to acheive the new state.

Note that changes involving creating or recreating Cloud Access Connectors requires a new connector token from the CAM Admin Console. Create a new connector to obtain a new token.

### Deleting the deployment
Run ```terraform destroy``` to remove all resources created by Terraform. Another alternative is to delete the resource group from Resource groups page in Azure. 

### Troubleshooting
- If the console is not changing, try pressing Enter to unfreeze it.
- If the script fails you can try rerunning the deployment again using ```terraform apply```.
- If CentOS workstations don't show up on CAM wait 5 minutes and refresh the page. If it still doesn't show up, try using ```terraform apply``` and check again after the completion of the script.
- If you are trying to run a fresh deployment and have been running into errors, you may need to delete ```terraform.tfstate``` and ```terraform.tfstate.backup```. .tfstate files store the state of your current infrastructure and configuration. 
