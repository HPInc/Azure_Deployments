# Teradici CAS Deployments on Azure
Teradici is the creator of the PCoIP remoting protocol technology and Cloud Access Software. Teradici's Cloud Access Software enables highly-scalable and cost-effective deployments by managing cloud compute costs and brokering PCoIP connections to remote Windows or Linux workstations. The Cloud Access Manager solution is comprised of two main components – the CAS Manager service, which is a service offered by Teradici to manage Cloud Access Manager deployments, and the Cloud Access Connector, which is the portion of the Cloud Access Manager solution that resides in the customer environment.  To learn more about Cloud Access Manager (CAS-M), please visit https://www.teradici.com/web-help/pcoip_cloud_access_manager/CACv2/

This repository contains a collection of Terraform scripts for demonstrating how to deploy Cloud Access Connectors in a user's Azure environments. __Note: These scripts are suitable for creating reference deployments for demonstration, evaluation, or development purposes. The infrastructure created may not meet the reliability, availability, or security requirements of your organization.__

![single-connector diagram](/terraform-deployments/docs/png/CASMArchitecture.png)

# CAS-Manager Stand Alone Deployments 

  - Single Connector Deployment
    - [CAS-M + CAC + AAD Domain Services](/terraform-deployments/docs/README-azure-casm-single-connector.md)
    - [CAS-M + CAC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-single-connector.md)
  - Load Balancer with Multi-Connector Deployment
    - [CAS-M + nCAC + AAD Domain Services](/terraform-deployments/docs/README-azure-casm-one-ip-lb.md)
    - [CAS-M + nCAC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-load-balancer-one-ip-lb.md)
  - Multi Region multi LB Deployment
    - [CAS-M + nCAC + AAD Domain Services](/terraform-deployments/docs/README-azure-multi-region-traffic-manager.md)
    - [CAS-M + nCAC + Local Domain Controller](/terraform-deployments/docs/README-azure-cas-mgr-multi-region-traffic-manager.md)

# CAS Manager As A Service Deployments
  
  ### CAS-M SaaS with Local Domain Controller (CAS-M SaaS + DC)
  - [Single-Connector Deployment](/terraform-deployments/docs/README-azure-single-connector.md)
  - [Load Balancer with Multi-Connector Deployment](/terraform-deployments/docs/README-azure-load-balancer.md)
  - [Multi Region multi LB Deployment](/terraform-deployments/docs/README-azure-multi-region-traffic-manager.md)

  ### QuickStart for CAS-M SaaS (Python script for creating CAS-M SaaS + DC)
  - [Quickstart Deployment CAS-M As A Service](/terraform-deployments/deployments/quickstart-single-connector/quickstart-tutorial.md)
  - [Step-by-Step Quickstart Deployment](/terraform-deployments/docs/terraform-config-step-by-step.md)
 
 
  ### FAQ: How to install AAD DS and Local License Server
  - [CASM (AADDS) Deployment](/terraform-deployments/docs/README-azure-casm-aadds.md)
  - [Local License Server (Single-Connector) Deployment](/terraform-deployments/docs/README-azure-lls-single-connector.md)


# AWS & GCP Deployments
- [Amazon Web Services](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/aws/README.md)
- [Google Cloud Platform](https://github.com/teradici/cloud_deployment_scripts/blob/master/docs/gcp/README.md)

# Directory structure
## deployments/
The top level terraform scripts that create specific deployments.

## docs/
Description and instructions for different deployments and architectures.

## modules/
The building blocks of deployments, e.g. a Domain Controller, a Cloud Access
Connector, a Workstation, etc.

## tools/
Various scripts to help with Terraform deployments.  e.g. a Python script to
generate random users for an Active Directory in a CSV file.

# Maintainer
If any security issues or bugs are found, or if there are feature requests, please contact support at support@teradici.com
