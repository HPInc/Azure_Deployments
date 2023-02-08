## Terraform Configuration

Before a deployment ```terraform.tfvars``` must be completed. This file contains different input variables for a deployment. In this example, we show the CAS Manager SaaS with Load Balancer.

**Note:** Uncommented lines show required variables, while commented lines show optional variables with their default or sample values.

1. Clone the repository into your Azure Cloud Shell (ACS) environment. 
    -   ```git clone https://github.com/teradici/Azure_Deployments``` 
    ![clone repo in ACS](/terraform-deployments/docs/png/git-clone-repo.png)
2. Change directory into: ```Azure_Deployments/terraform-deployments/deployments/load-balancer```.
    - ```cd Azure_Deployments/terraform-deployments/deployments/load-balancer```
    ![change directory](/terraform-deployments/docs/png/acs-change-directory.png)
3. Save ```terraform.tfvars.sample``` as ```terraform.tfvars```, and fill out the required variables. Use one of the following:
    - ```cp terraform.tfvars.sample terraform.tfvars``` (this will create a copy under a new name)
    - ```mv terraform.tfvars.sample terraform.tfvars``` (this will rename the file)
    ![copy tfvars file](/terraform-deployments/docs/png/copy-tfvars.png)
4. Configure the ```terraform.tfvars```file.
    - Edit files inside ACS by doing: ```code terraform.tfvars```.
    ![code terraform.tfvars](/terraform-deployments/docs/png/editing-tfvars.png)
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
        - ```isGFXHost```: Determines if a Graphics Agent will be installed. Graphics agents require [**NV-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series) or [**NCasT4_v3-series VMs**](https://docs.microsoft.com/en-us/azure/virtual-machines/nct4-v3-series). The default size in .tfvars is **Standard_NV6**. Additional VM sizes can be seen in the [**Appendix**](#appendix)
            -   Possible values: **true** or **false**

    2. cac_configuration:
        - ```cac_token```: token obtained from [CAS Manager](https://cas.teradici.com). This will be used when installing the Cloud Access Connector.
        ![obtaining a token](/terraform-deployments/docs/png/obtaining-cac-token.png)
        - ```location```: location of the CAC. Ensure this is identical to the workstations' location.

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
    
    9. SSL configuration (optional):
        -   [Link to SSL instructions](/terraform-deployments/docs/README-azure-load-balancer.md#5-optional-assigning-a-ssl-certificate)

    10. Azure key vault secrets (optional):
        -   [Link to Key Vault instructions](terraform-deployments/docs/README-azure-load-balancer.md#4-optional-storing-secrets-on-azure-key-vault)

5. **(Optional)** To add domain users save ```domain_users_list.csv.sample``` as ```domain_users_list.csv``` and edit this file accordingly.
    - **Note:** To add users successfully, passwords must have at least **3** of the following requirements:
      - 1 UPPERCASE letter
      - 1 lowercase letter
      - 1 number
      - 1 special character. e.g.: ```!@#$%^&*(*))_+```
6. Run ```terraform init``` to initialize a working directory containing Terraform configuration files.
7. Run ```terraform apply | tee -a installer.log``` to display resources that will be created by Terraform. 
    - ```| tee -a installer.log``` stores a local log of the script output which can be referred to later to help diagnose any problems.
    ![terraform apply prompt](/terraform-deployments/docs/png/terraform-apply-prompt.png)
8. Answer ```yes``` to start provisioning the load balancer infrastructure.
    - To skip this extra step, you may also provide the additional option using the command ```terraform apply --auto-approve```.
9. After completion, click [here](/terraform-deployments/docs/README-azure-load-balancer.md#7-adding-workstations-in-cas-manager) and start at section 7 for instructions to add workstations in the CAS Manager admin console. 

A typical deployment should take around 30-40 minutes. Upon a successful deployment, the output will display information such as important IP addresses and names. At the end of the deployment, the resources may still take a few minutes to start up completely. It takes a few minutes for a connector to sync with CAS Manager so **Health** statuses may temporarily show as **Unhealthy**. 

Completed deployment output:

![completed deployment](/terraform-deployments/docs/png/completed-deployment.png)

## Appendix

[Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
