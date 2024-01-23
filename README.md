# HP Anyware Deployments on Azure
HP Teradici is the creator of the PCoIP remoting protocol technology and HP Anyware. HP Anyware enables highly-scalable and cost-effective deployments by managing cloud compute costs and brokering PCoIP connections to remote Windows or Linux workstations. The Anyware Manager solution is comprised of two main components – the Anyware Manager service, which is a service offered by HP Teradici to manage Anyware Manager deployments, and the Anyware Connector, which is the portion of the Anyware Manager solution that resides in the customer environment.  To learn more about Anyware Manager (AWM), please visit https://www.teradici.com/web-help/cas_manager_as_a_service/

This repository contains a collection of Terraform scripts for demonstrating how to deploy Anyware Connectors in a user's Azure environments. __Note: These scripts are suitable for creating reference deployments for demonstration, evaluation, or development purposes. The infrastructure created may not meet the reliability, availability, or security requirements of your organization.__

<img src="/terraform-deployments/docs/png/HP-Anyware-architecture.png" width="90%" height="90%" title="Single Connector Terraform Deployment">

# HP Anyware Manager as a Service (AWM SaaS) Deployments
  
  ### AWM SaaS with Local Domain Controller (AWM SaaS + DC)
  - Single-Connector AWM SaaS + DC Deployment  
      - [Terrafrom script for Single Connector](/terraform-deployments/docs/README-azure-single-connector.md)  
      - [Quickstart Python script for Single Connector](/terraform-deployments/docs/README-azure-quickstart-single-connector.md)  
  - [Load Balancer with Multi-Connector Deployment](/terraform-deployments/docs/README-azure-load-balancer-one-ip.md)
  - [Multi Region Multi LB Deployment](/terraform-deployments/docs/README-azure-multi-region-traffic-manager.md)
     
  ### How to Start...
  - [HP Anyware Onboarding Documentation](/terraform-deployments/docs/README-azure-HP-anyware-onboard.md)
  - [How to setup Terraform variables for AWM SaaS](/terraform-deployments/docs/terraform-config-step-by-step.md)
  
  ### Reference 
  - [How to install AWM SaaS + AAD DS](/terraform-deployments/docs/README-azure-casm-aadds.md)
  - [How to install Local License Server (Single-Connector) Deployment](/terraform-deployments/docs/README-azure-lls-single-connector.md)
  - [Current VM sizes supported by PCoIP Graphics Agents](/terraform-deployments/docs/README-azure-vm-appendix.md)
  
# HP Anyware Manager Stand Alone Deployments

  - Single Connector Deployment
    - [AWM + AWC + AAD Domain Services](/terraform-deployments/docs/README-azure-casm-single-connector.md)
    - [AWM + AWC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-single-connector.md)
  - Load Balancer with Multi-Connector Deployment
    - [AWM + nAWC + AAD Domain Services](/terraform-deployments/docs/README-azure-casm-one-ip-lb.md)
    - [AWM + nAWC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-load-balancer-one-ip-lb.md)
  - Multi-Region Multi LB Deployment
    - [AWM + nAWC + AAD Domain Services](/terraform-deployments/docs/README-azure-casm-one-ip-tf.md)
    - [AWM + nAWC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-multi-region-traffic-manager.md)



# AWS & GCP Deployments
- [Amazon Web Services](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [Google Cloud Platform](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)


