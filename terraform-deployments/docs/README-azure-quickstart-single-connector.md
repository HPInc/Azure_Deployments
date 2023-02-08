# Single Cloud Access Connector QuickStart

## Introduction
The goal of this tutorial is to create the [single-connector](/terraform-deployments/docs/README-azure-single-connector.md) deployment in as few steps as possible by using Python and Terraform scripts.

This tutorial will guide you through the process of running the required Bash and Python scripts necessary in Azure Cloud Shell (ACS) to create the Cloud Access Connector deployment. The QuickStart feature is intended for use with the Cloud Shell as it makes deployment easy and ensures all the required dependencies are installed.

The Bash script will set the required environment variables in the Azure Cloud Shell. The Python script is a wrapper script that sets up the environment required for running Terraform scripts, which actually creates the ACS infrastructure such as Networking and Compute resources.

**Time to complete**: about 35 minutes, 45 minutes if graphics agents are included.


### Requirements
Running the deployment via Azure Cloud Shell:
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- a CAS Manager Deployment Service Account. CAS Manager can be accessed [here](https://cas.teradici.com/)
- A basic understanding of Azure, Terraform and using a command-line interpreter (Bash or PowerShell)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html)
- [Azure Cloud Shell](https://shell.azure.com) access.
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/) login

Running the deployment locally:
- Access to a subscription on Azure. 
- a PCoIP Registration Code. Contact sales [here](https://www.teradici.com/compare-plans) to purchase a subscription.
- a CAS Manager Deployment Service Account. CAS Manager can be accessed [here](https://cas.teradici.com/)
- [Terraform v0.13.5](https://www.terraform.io/downloads.html) or later
- Python 3.+
- PowerShell 5.+
- [PCoIP Client](https://docs.teradici.com/find/product/software-and-mobile-clients)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git/) login


### Deploying the Single-Connector via QuickStart scripts

1. Access the [Azure Cloud Shell](https://portal.azure.com/#cloudshell/).

2. Clone the repository into your Azure Cloud Shell (ACS) environment.
  - ```git clone https://github.azc.ext.hp.com/Anyware-Cloud-Solutions/Azure_Deployments_dev.git```

3. Change directory into the quickstart-single-connector folder:
  - ```cd Azure_Deployments_dev/terraform-deployments/deployments/quickstart-single-connector```

4. Run the deploy script first to have the required environment variables exported. The ARM Subscription and Tenant IDs will be set by running the command in Azure Cloud Shell: ```. deploy.sh```

5. Run the following command in Azure Cloud Shell: ```python azure-cloudshell-quickstart.py | tee -a output.txt```
  -   ```| tee -a output.txt``` logs the script's execution outputs into a .txt file.
  -   The script should take approximately 35-45 minutes to run.

6. The Python script will prompt the user for parameter inputs in order to set the desired configurations which include the following:
  - **pcoip_registration_code**: Enter your PCoIP Registration code. If you don't have one, visit [https://www.teradici.com/compare-plans](https://www.teradici.com/compare-plans)
  - **api_token**: Enter the API token from the Anyware Manager. Log into [https://cam.teradici.com](https://cam.teradici.com), click on your email address on the top right, and select **Get API token**.
  - **region**: Location of the deployment, default is ```westus2```. Options for east and central US are available as well via a dropdown selection prompt.
  - **workstations**: Enter the number of workstations to create. The machines that can be provisioned include a standard (s) and graphics (g) version of the Windows (win) and CentOS (cent) workstations:

Parameter | Description
--- | ---
scent | Standard CentOS 7 Workstation
gcent | CentOS 7 with NVIDIA Tesla T4 Virtual Workstation GPU
swin | Windows Server 2016 Workstation
gwin | Windows Server 2016 NVIDIA Tesla T4 Virtual Workstation GPU
  - Confirmation of desired configuration settings, allows user to proceed or make further changes prior to provisioning.
  - **ad_admin_password** & **safe_mode_admin_password** must have atleast 3 of the following requirements:
    - 1 UPPERCASE letter
    - 1 lowercase letter
    - 1 number
    - 1 special character. e.g.: !@#$%^&*(*))_+
  The single password and confirmation instance will set the value for each and both of the ad_admin_password and the safe_mode_admin_password parameters

7. The QuickStart Python and Terraform scripts will begin creating the architecture including the networks and compute resources required for the single-connector deployment.
In the case that the Azure Cloud Shell runs into some deployment issues, re-running the script should resolve any of the issues faced.

### Connect to a workstation

1. From a PCoIP client, connect to the public IP Address of the Cloud Access Connector.
    - Upon completion of the QuickStart deployment script, the public IP address will be output as a value. If the Cloud Shell times out, see the additional notes below.
2. Sign in with the **cas_admin** user credentials. The password will be the previously set credentials from step 5 of the Python script.
3. Select the desired workstation to be connected.

**Note:** When connecting to a workstation immediately after this script completes, the workstation (especially graphics ones) may still be setting up. You may see "Remote Desktop is restarting..." in the client. Please wait a few minutes or reconnect if it times out.

### Clean up
1. Change directory into ```~/terraform-deployments/deployments/quickstart-single-connector```
2. Use the command: ```python azure-cloudshell-quickstart.py cleanup``` to delete all deployment resources.
    -   If an error message shows, manually delete resource groups on the Azure Portal.
3. Log in to https://cam.teradici.com and delete the deployment named ```azure_quickstart_<timestamp>```

### Videos
A video of the deployment process for this script can be found on [Teradici's Youtube channel](https://youtu.be/Z69JEplUhDA)

### Additional notes
- If Azure Cloud Shell times out, you can look for the public IP address of the Cloud Access Connector on the Azure Portal.
  1. Go to the [Azure Portal](http://portal.azure.com/).
  2. Go into the **Resource groups** page.
  3. Click on the resource group that was created. It should look like ```single_connector_deployment_<timestamp>```.
  4. Click on the virtual machine ```cac-vm-0```.
  5. Under **Public IP address** is the value that will be entered in the PCoIP client.
- If the script stops at **'Adding cloud service account...'**, repeat the process of getting a new API token from [CAS Manager](https://cam.teradici.com) and replace it in ```azure-cloudshell-quickstart.cfg```.
- If the script stops at **'Adding "[machine-name]-0" to Cloud Access Manager...'**, you will need to [manually add machines](/terraform-deployments/docs/README-azure-single-connector.md#7-adding-workstations-in-cas-manager) on [CAS Manager](https://cam.teradici.com).
- The QuickStart script should add Azure Provider Subscriptions and Credentials to the Anyware Manager for deployment, in the case it is not already added users should fill in their Azure Credentials. The provider service account credentials are used where the Anyware Manager as a Service interacts directly with the cloud environment to perform actions such as powering a remote workstation on and off.

## Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
  
