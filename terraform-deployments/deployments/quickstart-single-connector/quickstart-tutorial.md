# Cloud Access Connector Quickstart

## Introduction
The goal of this tutorial is to create the [single-connector](https://github.com/teradici/Azure_Deployments/blob/master/terraform-deployments/docs/README-azure-single-deployment.md) deployment in as few steps as possible by using Python and Terraform scripts.

This tutorial will guide you in entering a few parameters in a configuration file before showing you how to run a Python script in Azure Cloud Shell (ACS) to create the Cloud Access Connector deployment.

The Python script is a wrapper script that sets up the environment required for running Terraform scripts, which actually creates the ACS infrastructure such as Networking and Compute resources.

**Time to complete**: about 35 minutes, 45 minutes if graphics agents are included.

## Modifying the Configuration File

Edit files inside Azure Cloud Shell by entering: ```code azure-cloudshell-quickstart.cfg```
1. **reg_code**: Replace **`<code>`** with your PCoIP Registration code. If you don't have one, visit [https://www.teradici.com/compare-plans](https://www.teradici.com/compare-plans)
2. **api_token**: Replace **`<token>`** with the Cloud Access Manager API token. Log into [https://cam.teradici.com](https://cam.teradici.com), click on your email address on the top right, and select **Get API token**.
3. **ad_admin_password** & **safe_mode_admin_password** must have atleast 3 of the following requirements:
    - 1 UPPERCASE letter
    - 1 lowercase letter
    - 1 number
    - 1 special character. e.g.: !@#$%^&*(*))_+
4. **region**: Location of the deployment, default is ```westus2```.
5. **workstations**: Enter the number of workstations to create.

Parameter | Description
--- | ---
scent | Standard CentOS 7 Workstation
gcent | CentOS 7 with NVIDIA Tesla T4 Virtual Workstation GPU
swin | Windows Server 2016 Workstation
gwin | Windows Server 2016 NVIDIA Tesla T4 Virtual Workstation GPU

After changes have been made, save (Ctrl + S) the  ```azure-cloudshell-quickstart.cfg``` file.

### Running the script

Run the following command in Azure Cloud Shell: ```azure-cloudshell-quickstart.py``` The script should take approximately 35-45 minutes to run.

### Connect to a workstation

1. From a PCoIP client, connect to the public IP Address of the Cloud Access Connector.
2. Sign in with the **cam_admin** user credentials. Default password is ```Password!234```.

**Note:** When connecting to a workstation immediately after this script completes, the workstation (especially graphics ones) may still be setting up. You may see "Remote Desktop is restarting..." in the client. Please wait a few minutes or reconnect if it times out.

### Clean up
1. Change directory into ```~/terraform-deployments\deployments\quickstart-single-connector```
2. Use the command: ```python azure-cloudshell-quickstart.py cleanup``` to delete all deployment resources.
    -   If an error message shows, manually delete resource groups on the Azure Portal.
3. Log in to https://cam.teradici.com and delete the deployment named ```azure_quickstart_<timestamp>```

### Additional notes
- If Azure Cloud Shell times out, you can look for the public IP address of the Cloud Access Connector on the Azure Portal.
  1. Go to the [Azure Portal](http://portal.azure.com/).
  2. Go into the **Resource groups** page.
  3. Click on the resource group that was created. It should look like ```single_connector_deployment_<timestamp>```.
  4. Click on the virtual machine ```cac-vm-0```.
  5. Under **Public IP address** is the value that will be entered in the PCoIP client.
  