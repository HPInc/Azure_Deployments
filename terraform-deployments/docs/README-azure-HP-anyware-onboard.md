# <center>**HP Anyware Onboarding Documentation**</center>
## Contents
[Brief introduction of main components](#_toc142569880)

[Single connector deployment](#_toc142569881)

[Connector Usage](#_toc142569882)

[Code Structure Review](#_toc142569883)

[Debug Notes](#_toc142569884)





## <a name="_toc142569880"></a>**Brief introduction of main components** 

<b>Anyware Connector (CAC or AWC): </b>
<br>
This virtual machine is normally called as “connector”. It operates in authentication and entitlement for remote workstation access. This is the core component, and all traffics will flow through it. We could have one or multiple connectors depending on the architecture. 
Connector = connector manager + connector broker + security gateway


<br>
<b>Anyware manager (AWM): </b>

This component can be hosted on a virtual machine or running as a service.
It provides a web UI to let administrators configure, manage and monitor brokering of remote workstations.

<br>
<b>Domain Controller (DC): </b>

Active directory is running on this component. It is used to store authentication data of agents and workstations. Connector VM will retrieve user auth and machine list from DC. 

<br>

## <a name="_toc142569881"></a>**Single connector deployment** 

### **Repos:**  
 - [Public Repo for Azure](https://github.com/HPInc/Azure_Deployments) 
 - [Private Enterprise Repo for Azure](https://github.azc.ext.hp.com/Anyware-Cloud-Solutions/Azure_Deployments_dev)
 - [Private Enterprise repo for AWS](https://github.azc.ext.hp.com/Anyware-Cloud-Solutions/cloud_deployment_scripts_dev)

 <br>

### **First Time Deployment:**  
 1. It is very important to read through corresponding README files before deploying any architectures. 
 2. Before making any deployment, it will be good to learn some basic knowledge about **Terraform** and **Azure Service Principle**.
 3. I recommand start with trying: [Terrafrom script for Single Connector](/terraform-deployments/docs/README-azure-single-connector.md). 
 4. To deploy/test our terraform deployments, we only need to edit “deploy.sh” for creating service principle and edit “terraform.tfvars” for assigning variable values. 
 5.	There are some required variables in “terraform.tfvars”, please make sure the properly value is assigned for each of them:
    - application_id
    - aad_client_secret
    - resource_group_name (it is optional but highly recommended)
    - ad_domain_users_list_file (it is optional but highly recommended. This csv file is used to register users info into local DC)
    - pcoip_registration_code
 6. Follow the instructions from README file to start deployment. 

<br>

### **Possible problems:** 


**Name conflict when you run “deploy.sh”:**   
Make sure you only run deploy script one time. If you want to generate a new service principle, you will need to delete the previous one from Azure portal and re-run the script again. 

**Time out when you run “deploy.sh”:**   
Check from Azure portal to make sure there is no service principle created; then, re-run the script. 

**Time out during “terraform apply”:**  
The deployment process is expected to take approximately 30-45 minutes. It is important to note that if you don't interact with the Azure portal during the deployment, the Azure Cloud Shell (ACS) session may time out. In such cases, the deployment process will not continue once you reconnect to the ACS. You will need to delete the created resource group manually from the Azure portal and reconnect to ACS. Then, you must manually run the following two commands before applying the Terraform script again from the beginning to initiate a fresh deployment.
 - export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
 - export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv)

**Error about missing subscription_id and tenant_id in azurerm block during “terraform apply”:**  
If the user manually or accidentally exits the current ACS session before the architecture successfully deployed, they need to manually execute the above two commands when a new ACS session starts (Make sure you already have a service principle).

<br>

## <a name="_toc142569882"></a>**Product Usage** 
### **Manage user and workstations through CAS manager**
The Admin Console enables you to create deployments, connectors and remote workstations all within a single console and from a single interface (UI).
You can find the tutorial about CAS manager from following link: [Overview - AWM](https://www.teradici.com/web-help/anyware_manager/23.04/admin_console/admin_console/) 

Link for CAS manager as service: [Anyware Manager](https://cas.teradici.com/) 

### **Establish PCoIP Session**
The following link provides the sequence diagram about how a PCoIP session is established and how the broker works: [PCoIP Brokered Connections](https://docs.teradici.com/knowledge/pcoip-brokered-connections)  

From this diagram, you could understand how components collaborate with each other when an agent makes the connection to his allocated VM through PCoIP client. 
You also can find the flow chart from the following link: [What are HP Anyware Products](https://docs.teradici.com/knowledge/what-are-teradici-products)   

These two diagrams are illustrating the same process in different ways. By combining the understanding from both diagrams, it will be easier for you to comprehend how a PCoIP session is established. 
 
### **About Connector**
Depending on the operating system of the virtual machine, you will need to download different connectors. Connector could be running on Ubuntu or Rocky 8. It is important to understand the difference between ‘CAC’ and ‘AWC’. The main differences between these two connectors lie in their installation and configuration processes.  

[Difference between Anyware Connector on Ubuntu and RHEL/Rocky Linux - HP Anyware Manager](https://www.teradici.com/web-help/anyware_manager/23.04/references/cac_differences/)   

For Ubuntu (CAC):
The installer is downloaded as a ‘tar.gz’ file. We call this connector as ‘CAC’ which stands for Cloud Access Connector. [Installing Connector on Ubuntu](https://www.teradici.com/web-help/anyware_manager/23.04/cloud_access_connector/cas_connector_install/)  

For Rocky 8: We need to install the Connector RPM. Note: there are some pre-request packages need to be installed. We call this connector as ‘AWC’ which stands for Anyware Connector. [Installing the Connector on RHEL/Rocky Linux](https://www.teradici.com/web-help/anyware_manager/23.04/cloud_access_connector/cas_connector_install_rhel/#3-installing-the-connector-rpm) 

<br>

## <a name="_toc142569883"></a>**Code Structure Review** 
The terraform code is mainly consisted by two parts: deployments and modules.  

**Deployments:**  
The "Deployments" directory serves as the main entry point for our architectures. You should select a specific deployment from this folder. Once you have chosen a deployment, you will need to assign values to variables in the "terraform.tfvars" file according to your specific requirements.  

The "domain_users_list.csv" file contains the list of agents that you intend to create. This file likely includes information such as first name, last name, username, password, and role. Note: the passwords must have at least **3** of the requirements: UPPERCASE letter; lowercase letter; number; special character. Otherwise, by default, the user will be disabled in the Domain Controller.  

The "main.tf" file serves as the entry point that invokes the corresponding modules. These modules are responsible for establishing Azure resources and setting up virtual machines based on the defined configuration.

**modules:**   
The "Modules" directory contains Terraform scripts for creating every component, including “AWM”, “DC”, “CAC”, “network”, workstations, and so on.   

These scripts not only create the necessary resources but also perform provisioning for each virtual machine. Provisioning Scripts are shell scripts that are used to set up the virtual machines. They handle tasks such as configuring services and installing packages. These scripts ensure that the virtual machines are properly configured and ready to perform their intended functions within the infrastructure.
  
<br>

## <a name="_toc142569884"></a>**Debug Notes** 
1. By default, SSH and RDP access are allowed for your current ACS IP. Once you have completed the deployment, you can directly SSH into the connector VM through the current ACS session. However, if you exit the current ACS session and open another session, you won't be able to SSH into the connector because the IP of ACS changes each time the session is reconnected. Therefore, to SSH into the connector in this scenario, you will need to manually add an inbound rule to your network security group (NSG) to allow traffic to port 22 from your IP. As per the policy, you can only allow traffic from a specific IP rather than allowing it from anywhere. After adding the inbound rule, you can open the command prompt on your device and SSH into the connector.

2. Same for using RDP. if you want to login to DC through RDP, you will need to manually add an inbound rule to your nsg.

3. If you have challenging questions about the Anyware connector/manager, you can use the following command on your connector VM to create a support bundle and seek assistance from the connector/manager team:
 > anyware-connector diagnose --support-bundle

 4. When you want to delete your current deployment from Azure, I recommend directly deleting the resource group from the Azure portal instead of using the "terraform destroy" command. This approach is faster and safer, as the command may not be able to completely delete everything due to errors.
