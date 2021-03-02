## Terraform Configuration

Before a deployment ```terraform.tfvars``` must be completed. This file contains different input variables for a deployment.
**Note:** Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

1. After cloning the repository into the [**ACS**](https://portal.azure.com/#cloudshell/) environment, change directory into: ```/terraform-deployments/deployments/load-balancer```.
    - **Tip**: to clone use ```git clone https://github.com/teradici/Azure_Deployments```
2. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables.
    - **Tip**: to copy use ```cp terraform.tfvars.sample terraform.tfvars```.
    - Edit files inside ACS by doing: ```code terraform.tfvars```.
    - To include optional variables, uncomment the line by removing preceding ```#```.
    - Make sure the locations of the connectors and work stations are identical.

    1. workstation configuration:
        - ```prefix```: prefix added to workstation machines. e.g.: 'tera0' will name a standard Linux VM **tera0**-scent-0
            -   Must be a max of 5 characters to avoid name cropping.
        - ```location```: location of the workstation. **westus** machines will be placed in the West US region. 
            -   Possible values: [Regions](https://azure.microsoft.com/en-us/global-infrastructure/geographies/). 
            -   e.g. West US 2 will be inputted as **westus2**. Central US as **centralus**.
        - ```workstation_os```: Operating system of the workstation.
            -   Possible values: **windows** or **linux**
        - ```vm_size```: Size of the virtual machine. 
            -   Possible values: [VM Sizes](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes). 
        - ```disk_type```: Type of storage for the workstation. 
            -   Possible values: **Standard_LRS**, **StandardSSD_LRS** or **Premium_LRS**.
        - ```count```: Number of workstations to deploy under the specific settings.
        - ```isGFXHost```: Determines if a Grahpics Agent will be installed. Graphics agents require [**NV-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) or [**NCasT4_v3-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series). The default size in .tfvars is **Standard_NV6**. Additional VM sizes can be seen in the [**Appendix**](#appendix)
            -   Possible values: **true** or **false**

    2. cac_configuration:
        - ```cac_token```: token obtained from [CAS Manager](https://cam.teradici.com/). This will be used when installing the Cloud Access Connector.
        - ```location```: location of the cac. Ensure this is identical to the workstations' location.

    3. resource_group_name:
        -   The name of the resource group that Azure resources will be placed under. If left commented, the resource group will be called ```load_balancer_deployment_[random_id]```
    
    4. prefix:
        -   Prefix added to Domain Controller and CAC machines. 
        -   Must be a max of 5 characters to avoid name cropping.
        -   e.g.: prefix of 'tera0' will name these VMS **tera0**-dc-vm and **tera0**-cac-vm-0
    
    5. create_debug_rdp_access:
        -   Setting this to ```true``` gives users RDP access into the Domain Controller VM. This can be configured after deployment completion to allow or deny access. 

    6. ad_domain_users_list_file:
        - The full path to the .csv file that contains domain users to be added to the deployment. 

    7. ad_admin_username:
        - The username for the active directory administrator.

    8. active_directory_netbios_name:
        -   The Active Directory NetBIOS name. 
        -   e.g.: 'tera' will create the domain 'tera.dns.internal'
    
    9. ssl configuration (optional):
        -   [Link to SSL instructions](/terraform-deployments/docs/README-azure-load-balancer.md#5-optional-assigning-a-ssl-certificate)

    10. Azure key vault secrets (optional):
        -   [Link to Key Vault instructions](terraform-deployments/docs/README-azure-load-balancer.md#4-optional-storing-secrets-on-azure-key-vault)

3. **(Optional)** To add domain users save ```domain_users_list.csv.sample``` as ```domain_users_list.csv``` and edit this file accordingly.
    - **Note:** To add users successfully, passwords must have atleast **3** of the following requirements:
      - 1 UPPERCASE letter
      - 1 lowercase letter
      - 1 number
      - 1 special character. e.g.: ```!@#$%^&*(*))_+```
4. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
5. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
    - **Note:** ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose any problems.
6. Answer ```yes``` to start provisioning the load-balancer infrastructure. 
7. After completion, click [here](/terraform-deployments/docs/README-azure-load-balancer.md#7-adding-workstations-in-cas-manager) for instructions to add workstations in the CAS Manager admin console. 

A typical deployment should take around 30-40 minutes. When finished, the script will display information such as IP addresses & names. At the end of the deployment, the resources may still take a few minutes to start up completely. It takes a few minutes for a connector to sync with CAS Manager so **Health** statuses may show as **Unhealthy** temporarily. 

Example output:
```
Apply complete! Resources: 77 added, 0 changed, 0 destroyed.

Outputs:

cac-vms = [
  {
    "name" = "cac-vm-0"
    "private_ip" = "10.0.3.4"
    "public_ip" = "52.109.24.176"
  },
]
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
load-balancer-public-ip = [
  {
    "public_ip" = "12.345.6.78"
  },
]
locations = [
  "westus2",
]
resource_group = "load_balancer_deployment_5f3520"
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

## Appendix
### Current VM sizes supported by PCoIP Graphics Agents

[NCasT4_v3-series VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series) powered by **NVIDIA Tesla T4 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max NICs / Expected network bandwidth (Mbps)**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NC4as_T4_v3**|4|28|180|1|16|8|2 / 8000|
|**Standard_NC8as_T4_v3**|8|56|360|1|16|16|4 / 8000|
|**Standard_NC16as_T4_v3**|16|110|360|1|16|32|8 / 8000|
|**Standard_NC64as_T4_v3**|64|440|2880|4|64|32|8 / 32000|


[NV-series VMs](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) powered by **NVIDIA Tesla M60 GPUs**.
|**Size**|**vCPU**|**Memory: GiB**|**Temp storage (SSD) GiB**|**GPU**|**GPU memory: GiB**|**Max data disks**|**Max NICs**|**Virtual Workstations**|**Virtual Applications**|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|**Standard_NV6**|6|56|340|1|8|24|1|1|25|
|**Standard_NV12**|12|112|680|2|16|48|2|2|50|
|**Standard_NV24**|24|224|1440|4|32|64|4|4|100|
